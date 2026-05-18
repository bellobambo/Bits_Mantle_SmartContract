// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Bits {
    enum Role {
        None,
        Landlord,
        Student,
        Investor
    }

    enum RentTerm {
        HalfYear,
        FullYear
    }

    struct User {
        string name;
        Role role;
        string matricNumber;
        string schoolName;
        bool registered;
    }

    struct House {
        uint256 id;
        address payable landlord;
        string hostelName;
        string hostelLocation;
        string schoolName;
        string proofOfOwnership;
        uint256 roomCount;
        uint256 availableRooms;
        uint256 yearlyRent;
        uint256 halfYearRent;
        uint256 propertyValue;
        uint256 totalInvested;
        bool fundingClosed;
        bool active;
    }

    struct HouseInput {
        string hostelName;
        string hostelLocation;
        string schoolName;
        string proofOfOwnership;
        string[] photos;
        uint256 roomCount;
        uint256 yearlyRent;
        uint256 halfYearRent;
        uint256 propertyValue;
    }

    struct Investment {
        uint256 houseId;
        address investor;
        uint256 amount;
        uint256 investedAt;
    }

    struct RentalReceipt {
        uint256 id;
        uint256 houseId;
        address student;
        string studentName;
        string studentSchoolName;
        address landlord;
        string landlordName;
        uint256 amountPaid;
        RentTerm term;
        uint256 paidAt;
        uint256 startDate;
        uint256 dueDate;
        uint256 endDate;
    }

    struct Payout {
        uint256 receiptId;
        uint256 houseId;
        address recipient;
        Role recipientRole;
        uint256 amount;
        uint256 paidAt;
    }

    uint256 public constant PLATFORM_RENT_SHARE_BPS = 1_000;
    uint256 public constant LANDLORD_RENT_SHARE_BPS = 1_000;
    uint256 public constant INVESTOR_RENT_SHARE_BPS = 8_000;
    uint256 public constant BPS_DENOMINATOR = 10_000;
    uint256 public constant RENT_START_DELAY = 7 days;
    uint256 public constant PAYMENT_GRACE_PERIOD = 30 days;
    uint256 public constant HALF_YEAR_DURATION = 182 days;
    uint256 public constant FULL_YEAR_DURATION = 365 days;

    uint256 public nextHouseId = 1;
    uint256 public nextReceiptId = 1;
    address payable public immutable platformOwner;

    mapping(address => User) public users;
    mapping(uint256 => House) private houses;
    mapping(uint256 => string[]) private housePhotos;
    mapping(uint256 => address[]) private houseInvestors;
    mapping(address => uint256[]) private housesByLandlord;
    mapping(address => uint256[]) private housesByInvestor;
    mapping(uint256 => RentalReceipt) private receipts;
    mapping(uint256 => mapping(address => Payout[])) private payoutsByHouseAndRecipient;
    mapping(uint256 => mapping(address => uint256)) public investedByHouse;
    mapping(uint256 => mapping(address => uint256)) public investedAtByHouse;
    mapping(uint256 => mapping(address => bool)) private isHouseInvestor;

    event UserRegistered(address indexed user, string name, Role role, string matricNumber, string schoolName);
    event HouseUploaded(uint256 indexed houseId, address indexed landlord, uint256 propertyValue);
    event HouseInvestment(uint256 indexed houseId, address indexed investor, uint256 amount);
    event HouseFundingClosed(uint256 indexed houseId, uint256 totalInvested);
    event RentPaid(
        uint256 indexed receiptId,
        uint256 indexed houseId,
        address indexed student,
        uint256 amount,
        uint256 startDate,
        uint256 dueDate,
        uint256 endDate
    );
    event RentDistributed(
        uint256 indexed houseId, uint256 platformAmount, uint256 landlordAmount, uint256 investorAmount
    );
    event PayoutRecorded(
        uint256 indexed receiptId,
        uint256 indexed houseId,
        address indexed recipient,
        Role recipientRole,
        uint256 amount
    );

    constructor() {
        platformOwner = payable(msg.sender);
    }

    modifier onlyRegisteredRole(Role requiredRole) {
        require(users[msg.sender].registered, "Bits: user not registered");
        require(users[msg.sender].role == requiredRole, "Bits: wrong role");
        _;
    }

    function register(string calldata name, Role role, string calldata matricNumber, string calldata schoolName)
        external
    {
        require(!users[msg.sender].registered, "Bits: already registered");
        require(bytes(name).length != 0, "Bits: name required");
        require(role == Role.Landlord || role == Role.Student || role == Role.Investor, "Bits: invalid role");

        if (role == Role.Student) {
            require(bytes(matricNumber).length != 0, "Bits: matric number required");
            require(bytes(schoolName).length != 0, "Bits: school required");
        } else {
            require(bytes(matricNumber).length == 0, "Bits: matric only for students");
            require(bytes(schoolName).length == 0, "Bits: school only for students");
        }

        users[msg.sender] =
            User({name: name, role: role, matricNumber: matricNumber, schoolName: schoolName, registered: true});

        emit UserRegistered(msg.sender, name, role, matricNumber, schoolName);
    }

    function uploadHouse(HouseInput calldata input)
        external
        onlyRegisteredRole(Role.Landlord)
        returns (uint256 houseId)
    {
        require(bytes(input.hostelName).length != 0, "Bits: hostel name required");
        require(bytes(input.hostelLocation).length != 0, "Bits: location required");
        require(bytes(input.schoolName).length != 0, "Bits: school required");
        require(bytes(input.proofOfOwnership).length != 0, "Bits: ownership proof required");
        require(input.photos.length != 0, "Bits: photos required");
        require(input.roomCount != 0, "Bits: rooms required");
        require(input.yearlyRent != 0, "Bits: yearly rent required");
        require(input.halfYearRent != 0, "Bits: half-year rent required");
        require(input.propertyValue != 0, "Bits: property value required");

        houseId = nextHouseId++;
        houses[houseId] = House({
            id: houseId,
            landlord: payable(msg.sender),
            hostelName: input.hostelName,
            hostelLocation: input.hostelLocation,
            schoolName: input.schoolName,
            proofOfOwnership: input.proofOfOwnership,
            roomCount: input.roomCount,
            availableRooms: input.roomCount,
            yearlyRent: input.yearlyRent,
            halfYearRent: input.halfYearRent,
            propertyValue: input.propertyValue,
            totalInvested: 0,
            fundingClosed: false,
            active: true
        });

        for (uint256 i = 0; i < input.photos.length; i++) {
            require(bytes(input.photos[i]).length != 0, "Bits: empty photo");
            housePhotos[houseId].push(input.photos[i]);
        }

        housesByLandlord[msg.sender].push(houseId);

        emit HouseUploaded(houseId, msg.sender, input.propertyValue);
    }

    function invest(uint256 houseId) external payable onlyRegisteredRole(Role.Investor) {
        House storage house = houses[houseId];
        require(house.active, "Bits: house not active");
        require(!house.fundingClosed, "Bits: funding closed");
        require(msg.sender != house.landlord, "Bits: landlord cannot invest");

        uint256 minimumInvestment = (house.propertyValue * 10) / 100;
        uint256 maximumInvestment = (house.propertyValue * 50) / 100;
        require(msg.value >= minimumInvestment, "Bits: below 10 percent minimum");
        require(msg.value <= maximumInvestment, "Bits: above 50 percent maximum");
        require(house.totalInvested + msg.value <= house.propertyValue, "Bits: exceeds property value");

        if (!isHouseInvestor[houseId][msg.sender]) {
            isHouseInvestor[houseId][msg.sender] = true;
            houseInvestors[houseId].push(msg.sender);
            housesByInvestor[msg.sender].push(houseId);
        }

        house.totalInvested += msg.value;
        investedByHouse[houseId][msg.sender] += msg.value;
        investedAtByHouse[houseId][msg.sender] = block.timestamp;

        _sendValue(house.landlord, msg.value);

        if (house.totalInvested == house.propertyValue) {
            house.fundingClosed = true;
            emit HouseFundingClosed(houseId, house.totalInvested);
        }

        emit HouseInvestment(houseId, msg.sender, msg.value);
    }

    function payRent(uint256 houseId, RentTerm term)
        external
        payable
        onlyRegisteredRole(Role.Student)
        returns (uint256 receiptId)
    {
        House storage house = houses[houseId];
        require(house.active, "Bits: house not active");
        require(house.availableRooms != 0, "Bits: no rooms available");

        uint256 rentAmount = term == RentTerm.FullYear ? house.yearlyRent : house.halfYearRent;
        require(msg.value == rentAmount, "Bits: incorrect rent amount");

        house.availableRooms -= 1;

        receiptId = _createReceipt(houseId, house.landlord, term, msg.value);
        _distributeRent(receiptId, houseId, msg.value);
    }

    function getHousePhotos(uint256 houseId) external view returns (string[] memory) {
        return housePhotos[houseId];
    }

    function getHouse(uint256 houseId) external view returns (House memory) {
        return houses[houseId];
    }

    function getAllHouses() external view returns (House[] memory allHouses) {
        uint256 totalHouses = nextHouseId - 1;
        allHouses = new House[](totalHouses);

        for (uint256 i = 0; i < totalHouses; i++) {
            allHouses[i] = houses[i + 1];
        }
    }

    function getOwnerHouses(address landlord) external view returns (House[] memory ownerHouses) {
        uint256[] storage houseIds = housesByLandlord[landlord];
        ownerHouses = new House[](houseIds.length);

        for (uint256 i = 0; i < houseIds.length; i++) {
            ownerHouses[i] = houses[houseIds[i]];
        }
    }

    function getInvestorHouses(address investor) external view returns (House[] memory investorHouses) {
        uint256[] storage houseIds = housesByInvestor[investor];
        investorHouses = new House[](houseIds.length);

        for (uint256 i = 0; i < houseIds.length; i++) {
            investorHouses[i] = houses[houseIds[i]];
        }
    }

    function getHouseInvestors(uint256 houseId) external view returns (address[] memory) {
        return houseInvestors[houseId];
    }

    function getInvestment(uint256 houseId, address investor) external view returns (Investment memory) {
        return Investment({
            houseId: houseId,
            investor: investor,
            amount: investedByHouse[houseId][investor],
            investedAt: investedAtByHouse[houseId][investor]
        });
    }

    function getReceipt(uint256 receiptId) external view returns (RentalReceipt memory) {
        return receipts[receiptId];
    }

    function getPayoutHistory(uint256 houseId, address recipient) external view returns (Payout[] memory) {
        return payoutsByHouseAndRecipient[houseId][recipient];
    }

    function getMyPayoutHistory(uint256 houseId) external view returns (Payout[] memory) {
        return payoutsByHouseAndRecipient[houseId][msg.sender];
    }

    function houseCount() external view returns (uint256) {
        return nextHouseId - 1;
    }

    function receiptCount() external view returns (uint256) {
        return nextReceiptId - 1;
    }

    function _distributeRent(uint256 receiptId, uint256 houseId, uint256 rentAmount)
        private
        returns (uint256 platformAmount, uint256 landlordAmount, uint256 investorAmount)
    {
        House storage house = houses[houseId];

        platformAmount = (rentAmount * PLATFORM_RENT_SHARE_BPS) / BPS_DENOMINATOR;
        _sendValue(platformOwner, platformAmount);

        if (house.totalInvested == 0) {
            landlordAmount = rentAmount - platformAmount;
            _sendValue(house.landlord, landlordAmount);
            _recordPayout(receiptId, houseId, house.landlord, Role.Landlord, landlordAmount);
            emit RentDistributed(houseId, platformAmount, landlordAmount, investorAmount);
            return (platformAmount, landlordAmount, 0);
        }

        uint256 baseLandlordAmount = (rentAmount * LANDLORD_RENT_SHARE_BPS) / BPS_DENOMINATOR;
        uint256 maximumInvestorAmount = (rentAmount * INVESTOR_RENT_SHARE_BPS) / BPS_DENOMINATOR;
        investorAmount = (maximumInvestorAmount * house.totalInvested) / house.propertyValue;
        uint256 unfundedLandlordAmount = maximumInvestorAmount - investorAmount;
        landlordAmount = baseLandlordAmount + unfundedLandlordAmount;
        _payInvestors(receiptId, houseId, investorAmount, house.totalInvested);

        _sendValue(house.landlord, landlordAmount);
        _recordPayout(receiptId, houseId, house.landlord, Role.Landlord, landlordAmount);

        emit RentDistributed(houseId, platformAmount, landlordAmount, investorAmount);
    }

    function _payInvestors(uint256 receiptId, uint256 houseId, uint256 investorAmount, uint256 totalInvested) private {
        uint256 remainingInvestorAmount = investorAmount;
        address[] storage investors = houseInvestors[houseId];

        for (uint256 i = 0; i < investors.length; i++) {
            address investor = investors[i];
            uint256 payout;

            if (i == investors.length - 1) {
                payout = remainingInvestorAmount;
            } else {
                payout = (investorAmount * investedByHouse[houseId][investor]) / totalInvested;
                remainingInvestorAmount -= payout;
            }

            _sendValue(payable(investor), payout);
            _recordPayout(receiptId, houseId, investor, Role.Investor, payout);
        }
    }

    function _createReceipt(uint256 houseId, address landlordAddress, RentTerm term, uint256 amount)
        private
        returns (uint256 receiptId)
    {
        uint256 paidAt = block.timestamp;
        uint256 startDate = paidAt + RENT_START_DELAY;
        uint256 dueDate = startDate + (term == RentTerm.FullYear ? FULL_YEAR_DURATION : HALF_YEAR_DURATION);
        uint256 endDate = dueDate + PAYMENT_GRACE_PERIOD;
        User storage student = users[msg.sender];
        User storage landlord = users[landlordAddress];

        receiptId = nextReceiptId++;
        receipts[receiptId] = RentalReceipt({
            id: receiptId,
            houseId: houseId,
            student: msg.sender,
            studentName: student.name,
            studentSchoolName: student.schoolName,
            landlord: landlordAddress,
            landlordName: landlord.name,
            amountPaid: amount,
            term: term,
            paidAt: paidAt,
            startDate: startDate,
            dueDate: dueDate,
            endDate: endDate
        });

        emit RentPaid(receiptId, houseId, msg.sender, amount, startDate, dueDate, endDate);
    }

    function _recordPayout(uint256 receiptId, uint256 houseId, address recipient, Role recipientRole, uint256 amount)
        private
    {
        payoutsByHouseAndRecipient[houseId][recipient].push(
            Payout({
                receiptId: receiptId,
                houseId: houseId,
                recipient: recipient,
                recipientRole: recipientRole,
                amount: amount,
                paidAt: block.timestamp
            })
        );

        emit PayoutRecorded(receiptId, houseId, recipient, recipientRole, amount);
    }

    function _sendValue(address payable recipient, uint256 amount) private {
        if (amount == 0) {
            return;
        }

        (bool success,) = recipient.call{value: amount}("");
        require(success, "Bits: transfer failed");
    }
}
