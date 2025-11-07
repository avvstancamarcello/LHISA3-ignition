// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca – Lawyer, Italy (Florence)
// © Copyright Marcello Stanca, Firenze, Italy


contract SolidaryGovernance {
    struct Proposal {
        string title;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        bool validated;
        address proposer;
    }

    Proposal[] public proposals;
    mapping(address => mapping(uint256 => bool)) public hasVoted;

    event ProposalCreated(uint256 indexed id, string title, address proposer);
    event Voted(uint256 indexed id, address voter, bool support);
    event ProposalValidated(uint256 indexed id);

    modifier onlyDuringVoting(uint256 id) {
        require(block.timestamp <= proposals[id].deadline, "Voting closed");
        _;
    }

    function createProposal(string memory title, string memory description, uint256 duration) external {
        proposals.push(Proposal(title, description, 0, 0, block.timestamp + duration, false, msg.sender));
        emit ProposalCreated(proposals.length - 1, title, msg.sender);
    }

    function vote(uint256 id, bool support) external onlyDuringVoting(id) {
        require(!hasVoted[msg.sender][id], "Already voted");
        hasVoted[msg.sender][id] = true;

        if (support) proposals[id].votesFor++;
        else proposals[id].votesAgainst++;

        emit Voted(id, msg.sender, support);
    }

    function validateProposal(uint256 id) external {
        Proposal storage p = proposals[id];
        require(block.timestamp > p.deadline, "Voting still active");
        require(!p.validated, "Already validated");
        require(p.votesFor > p.votesAgainst, "Not approved");

        p.validated = true;
        emit ProposalValidated(id);
    }

    function getProposal(uint256 id) external view returns (Proposal memory) {
        return proposals[id];
    }
}
