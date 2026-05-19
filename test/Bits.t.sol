// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bits} from "../src/Bits.sol";

contract BitsTest is Test {
    Bits public bits;

    address landlord = address(0xA11CE);
    address investorOne = address(0xB0B);
    address investorTwo = address(0xCAFE);
    address student = address(0xD00D);
    address platformOwner = address(this);

    uint256 propertyValue = 200 ether;
    uint256 yearlyRent = 12 ether;
    uint256 halfYearRent = 7 ether;

    receive() external payable {}

    function setUp() public {
        bits = new Bits();

        vm.deal(landlord, 1 ether);
        vm.deal(investorOne, 200 ether);
        vm.deal(investorTwo, 100 ether);
        vm.deal(student, 20 ether);

        vm.prank(landlord);
        bits.register("Ada Landlord", Bits.Role.Landlord, "", "");

        vm.prank(investorOne);
        bits.register("Bola Investor", Bits.Role.Investor, "", "");

        vm.prank(investorTwo);
        bits.register("Chika Investor", Bits.Role.Investor, "", "");

        vm.prank(student);
        bits.register("Dayo Student", Bits.Role.Student, "CSC/2024/001", "University of Lagos");
    }

    function test_RegisterStoresStudentMatricNumber() public view {
        (string memory name, Bits.Role role, string memory matricNumber, string memory schoolName, bool registered) =
            bits.users(student);

        assertEq(name, "Dayo Student");
        assertEq(uint256(role), uint256(Bits.Role.Student));
        assertEq(matricNumber, "CSC/2024/001");
        assertEq(schoolName, "University of Lagos");
        assertTrue(registered);
    }

    function test_LandlordCanUploadHouse() public {
        uint256 houseId = _uploadHouse();

        Bits.House memory house = bits.getHouse(houseId);

        assertEq(house.id, houseId);
        assertEq(house.landlord, landlord);
        assertEq(house.hostelName, "Bits Lodge");
        assertEq(house.hostelLocation, "University Road, Lagos");
        assertEq(house.schoolName, "University of Lagos");
        assertEq(house.proofOfOwnership, "ipfs://proof");
        assertEq(house.roomCount, 10);
        assertEq(house.availableRooms, 10);
        assertEq(house.yearlyRent, yearlyRent);
        assertEq(house.halfYearRent, halfYearRent);
        assertEq(house.propertyValue, propertyValue);
        assertEq(house.totalInvested, 0);
        assertFalse(house.fundingClosed);
        assertTrue(house.active);

        string[] memory photos = bits.getHousePhotos(houseId);
        assertEq(photos.length, 2);
        assertEq(photos[0], "ipfs://front");
        assertEq(photos[1], "ipfs://room");
    }

    function test_CanFetchAllOwnerAndInvestorHouses() public {
        uint256 firstHouseId = _uploadHouse();
        uint256 secondHouseId = _uploadHouse();

        vm.prank(investorOne);
        bits.invest{value: 20 ether}(firstHouseId);

        Bits.House[] memory allHouses = bits.getAllHouses();
        Bits.House[] memory ownerHouses = bits.getOwnerHouses(landlord);
        Bits.House[] memory investorHouses = bits.getInvestorHouses(investorOne);

        assertEq(allHouses.length, 2);
        assertEq(allHouses[0].id, firstHouseId);
        assertEq(allHouses[1].id, secondHouseId);

        assertEq(ownerHouses.length, 2);
        assertEq(ownerHouses[0].id, firstHouseId);
        assertEq(ownerHouses[1].id, secondHouseId);

        assertEq(investorHouses.length, 1);
        assertEq(investorHouses[0].id, firstHouseId);
    }

    function test_InvestorInvestmentMustBeBetweenTenAndFiftyPercent() public {
        uint256 houseId = _uploadHouse();

        vm.startPrank(investorOne);
        vm.expectRevert("Bits: below 10 percent minimum");
        bits.invest{value: 19 ether}(houseId);

        vm.expectRevert("Bits: above 50 percent maximum");
        bits.invest{value: 101 ether}(houseId);
        vm.stopPrank();

        uint256 landlordBalanceBefore = landlord.balance;

        vm.prank(investorOne);
        bits.invest{value: 20 ether}(houseId);

        assertEq(bits.investedByHouse(houseId, investorOne), 20 ether);
        assertEq(landlord.balance, landlordBalanceBefore + 20 ether);
    }

    function test_LandlordStoresPropertyVerificationAIReview() public {
        uint256 houseId = _uploadHouse();
        bytes32 evidenceHash = keccak256("property-ai-review");

        vm.warp(1_700_000_000);
        vm.prank(landlord);
        uint256 reviewId = bits.storePropertyVerificationReview(
            houseId,
            "verified",
            9_200,
            "Ownership proof, landlord name, and property location matched.",
            evidenceHash,
            "ipfs://ai-property-review"
        );

        assertEq(reviewId, 1);
        assertEq(bits.getAIReviewCount(houseId), 1);

        Bits.AIReview memory review = bits.getAIReview(houseId, 0);
        assertEq(review.id, reviewId);
        assertEq(review.houseId, houseId);
        assertEq(uint256(review.reviewType), uint256(Bits.AIReviewType.PropertyVerification));
        assertEq(review.reviewer, landlord);
        assertEq(uint256(review.reviewerRole), uint256(Bits.Role.Landlord));
        assertEq(review.status, "verified");
        assertEq(review.confidenceBps, 9_200);
        assertEq(review.summary, "Ownership proof, landlord name, and property location matched.");
        assertEq(review.evidenceHash, evidenceHash);
        assertEq(review.evidenceURI, "ipfs://ai-property-review");
        assertEq(review.createdAt, 1_700_000_000);

        Bits.AIReview[] memory reviews = bits.getAIReviews(houseId);
        assertEq(reviews.length, 1);
        assertEq(reviews[0].id, reviewId);
    }

    function test_OnlyHouseLandlordCanStorePropertyVerificationAIReview() public {
        uint256 houseId = _uploadHouse();

        vm.prank(investorOne);
        vm.expectRevert("Bits: wrong role");
        bits.storePropertyVerificationReview(
            houseId,
            "verified",
            9_200,
            "Ownership proof matched.",
            keccak256("property-ai-review"),
            "ipfs://ai-property-review"
        );

        vm.prank(student);
        vm.expectRevert("Bits: wrong role");
        bits.storePropertyVerificationReview(
            houseId,
            "verified",
            9_200,
            "Ownership proof matched.",
            keccak256("property-ai-review"),
            "ipfs://ai-property-review"
        );
    }

    function test_InvestorStoresInvestmentAIReview() public {
        uint256 houseId = _uploadHouse();
        bytes32 evidenceHash = keccak256("investment-ai-review");

        vm.warp(1_700_000_000);
        vm.prank(investorOne);
        uint256 reviewId = bits.storeInvestmentReview(
            houseId,
            "moderate",
            7_800,
            "Rent and occupancy look viable, but funding concentration should be monitored.",
            evidenceHash,
            "ipfs://ai-investment-review"
        );

        assertEq(reviewId, 1);
        assertEq(bits.getAIReviewCount(houseId), 1);

        Bits.AIReview memory review = bits.getAIReview(houseId, 0);
        assertEq(review.id, reviewId);
        assertEq(review.houseId, houseId);
        assertEq(uint256(review.reviewType), uint256(Bits.AIReviewType.InvestmentReview));
        assertEq(review.reviewer, investorOne);
        assertEq(uint256(review.reviewerRole), uint256(Bits.Role.Investor));
        assertEq(review.status, "moderate");
        assertEq(review.confidenceBps, 7_800);
        assertEq(review.summary, "Rent and occupancy look viable, but funding concentration should be monitored.");
        assertEq(review.evidenceHash, evidenceHash);
        assertEq(review.evidenceURI, "ipfs://ai-investment-review");
        assertEq(review.createdAt, 1_700_000_000);
    }

    function test_AIReviewRequiresValidHouseStatusSummaryAndConfidence() public {
        uint256 houseId = _uploadHouse();

        vm.startPrank(investorOne);

        vm.expectRevert("Bits: invalid house");
        bits.storeInvestmentReview(
            999,
            "moderate",
            7_800,
            "Review summary.",
            keccak256("investment-ai-review"),
            "ipfs://ai-investment-review"
        );

        vm.expectRevert("Bits: review status required");
        bits.storeInvestmentReview(
            houseId,
            "",
            7_800,
            "Review summary.",
            keccak256("investment-ai-review"),
            "ipfs://ai-investment-review"
        );

        vm.expectRevert("Bits: review summary required");
        bits.storeInvestmentReview(
            houseId,
            "moderate",
            7_800,
            "",
            keccak256("investment-ai-review"),
            "ipfs://ai-investment-review"
        );

        vm.expectRevert("Bits: invalid confidence");
        bits.storeInvestmentReview(
            houseId,
            "moderate",
            10_001,
            "Review summary.",
            keccak256("investment-ai-review"),
            "ipfs://ai-investment-review"
        );

        vm.stopPrank();
    }

    function test_StudentPaysRentAndGetsReceiptDates() public {
        uint256 houseId = _uploadHouse();
        vm.warp(1_700_000_000);

        vm.prank(student);
        uint256 receiptId = bits.payRent{value: yearlyRent}(houseId, Bits.RentTerm.FullYear);

        Bits.RentalReceipt memory receipt = bits.getReceipt(receiptId);

        assertEq(receipt.id, receiptId);
        assertEq(receipt.houseId, houseId);
        assertEq(receipt.student, student);
        assertEq(receipt.studentName, "Dayo Student");
        assertEq(receipt.studentSchoolName, "University of Lagos");
        assertEq(receipt.landlord, landlord);
        assertEq(receipt.landlordName, "Ada Landlord");
        assertEq(receipt.amountPaid, yearlyRent);
        assertEq(uint256(receipt.term), uint256(Bits.RentTerm.FullYear));
        assertEq(receipt.paidAt, 1_700_000_000);
        assertEq(receipt.startDate, 1_700_000_000 + 7 days);
        assertEq(receipt.dueDate, receipt.startDate + 365 days);
        assertEq(receipt.endDate, receipt.dueDate + 30 days);
    }

    function test_RentSplitsFundedInvestorShareAndReturnsUnfundedShareToLandlord() public {
        uint256 houseId = _uploadHouse();

        vm.prank(investorOne);
        bits.invest{value: 40 ether}(houseId);

        vm.prank(investorTwo);
        bits.invest{value: 60 ether}(houseId);

        uint256 platformBefore = platformOwner.balance;
        uint256 landlordBefore = landlord.balance;
        uint256 investorOneBefore = investorOne.balance;
        uint256 investorTwoBefore = investorTwo.balance;

        vm.prank(student);
        bits.payRent{value: yearlyRent}(houseId, Bits.RentTerm.FullYear);

        assertEq(platformOwner.balance, platformBefore + 1.2 ether);
        assertEq(landlord.balance, landlordBefore + 6 ether);
        assertEq(investorOne.balance, investorOneBefore + 1.92 ether);
        assertEq(investorTwo.balance, investorTwoBefore + 2.88 ether);
    }

    function test_LandlordAndInvestorsCanSeePayoutHistoryPerHouse() public {
        uint256 houseId = _uploadHouse();

        vm.prank(investorOne);
        bits.invest{value: 40 ether}(houseId);

        vm.prank(investorTwo);
        bits.invest{value: 60 ether}(houseId);

        vm.warp(1_700_000_000);
        vm.prank(student);
        uint256 receiptId = bits.payRent{value: yearlyRent}(houseId, Bits.RentTerm.FullYear);

        Bits.Payout[] memory landlordPayouts = bits.getPayoutHistory(houseId, landlord);
        Bits.Payout[] memory investorOnePayouts = bits.getPayoutHistory(houseId, investorOne);
        Bits.Payout[] memory investorTwoPayouts = bits.getPayoutHistory(houseId, investorTwo);

        assertEq(landlordPayouts.length, 1);
        assertEq(landlordPayouts[0].receiptId, receiptId);
        assertEq(landlordPayouts[0].houseId, houseId);
        assertEq(landlordPayouts[0].recipient, landlord);
        assertEq(uint256(landlordPayouts[0].recipientRole), uint256(Bits.Role.Landlord));
        assertEq(landlordPayouts[0].amount, 6 ether);
        assertEq(landlordPayouts[0].paidAt, 1_700_000_000);

        assertEq(investorOnePayouts.length, 1);
        assertEq(investorOnePayouts[0].receiptId, receiptId);
        assertEq(investorOnePayouts[0].recipient, investorOne);
        assertEq(uint256(investorOnePayouts[0].recipientRole), uint256(Bits.Role.Investor));
        assertEq(investorOnePayouts[0].amount, 1.92 ether);

        assertEq(investorTwoPayouts.length, 1);
        assertEq(investorTwoPayouts[0].receiptId, receiptId);
        assertEq(investorTwoPayouts[0].recipient, investorTwo);
        assertEq(uint256(investorTwoPayouts[0].recipientRole), uint256(Bits.Role.Investor));
        assertEq(investorTwoPayouts[0].amount, 2.88 ether);
    }

    function test_SingleTenPercentInvestorOnlyEarnsTenPercentOfInvestorPool() public {
        uint256 houseId = _uploadHouse();

        vm.prank(investorOne);
        bits.invest{value: 20 ether}(houseId);

        uint256 landlordBefore = landlord.balance;
        uint256 investorBefore = investorOne.balance;

        vm.prank(student);
        bits.payRent{value: yearlyRent}(houseId, Bits.RentTerm.FullYear);

        assertEq(investorOne.balance, investorBefore + 0.96 ether);
        assertEq(landlord.balance, landlordBefore + 9.84 ether);
    }

    function test_FundingClosesWhenPropertyValueIsMet() public {
        uint256 houseId = _uploadHouse();

        vm.prank(investorOne);
        bits.invest{value: 100 ether}(houseId);

        vm.prank(investorTwo);
        bits.invest{value: 100 ether}(houseId);

        Bits.House memory house = bits.getHouse(houseId);
        assertEq(house.totalInvested, propertyValue);
        assertTrue(house.fundingClosed);

        vm.expectRevert("Bits: funding closed");
        vm.prank(investorOne);
        bits.invest{value: 20 ether}(houseId);
    }

    function _uploadHouse() internal returns (uint256) {
        string[] memory photos = new string[](2);
        photos[0] = "ipfs://front";
        photos[1] = "ipfs://room";

        vm.prank(landlord);
        return bits.uploadHouse(
            Bits.HouseInput({
                hostelName: "Bits Lodge",
                hostelLocation: "University Road, Lagos",
                schoolName: "University of Lagos",
                proofOfOwnership: "ipfs://proof",
                photos: photos,
                roomCount: 10,
                yearlyRent: yearlyRent,
                halfYearRent: halfYearRent,
                propertyValue: propertyValue
            })
        );
    }
}
