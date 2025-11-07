// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca Lawyer - ITALY Florence

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DiagnosticBooking is Ownable {
    IERC20 public paymentToken;
    uint256 public bookingFee;

    struct Booking {
        address patient;
        uint256 timestamp;
        bool confirmed;
    }

    Booking[] public bookings;

    event BookingRequested(address indexed patient, uint256 timestamp);
    event BookingConfirmed(uint256 indexed bookingId);

    constructor(address initialOwner, address tokenAddress) Ownable(initialOwner) {
        paymentToken = IERC20(tokenAddress);
        bookingFee = 10 * 1e18; // default fee: 10 tokens
    }

    function requestBooking() external {
        require(paymentToken.transferFrom(msg.sender, address(this), bookingFee), "Payment failed");
        bookings.push(Booking(msg.sender, block.timestamp, false));
        emit BookingRequested(msg.sender, block.timestamp);
    }

    function confirmBooking(uint256 bookingId) external onlyOwner {
        require(bookingId < bookings.length, "Invalid booking ID");
        bookings[bookingId].confirmed = true;
        emit BookingConfirmed(bookingId);
    }

    function getBooking(uint256 bookingId) external view returns (address, uint256, bool) {
        require(bookingId < bookings.length, "Invalid booking ID");
        Booking memory b = bookings[bookingId];
        return (b.patient, b.timestamp, b.confirmed);
    }

    function updateFee(uint256 newFee) external onlyOwner {
        bookingFee = newFee;
    }

    function withdrawTokens(address to, uint256 amount) external onlyOwner {
        require(paymentToken.transfer(to, amount), "Withdraw failed");
    }
}
