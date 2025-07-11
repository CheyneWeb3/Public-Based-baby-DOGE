// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract ERC20LotteryV2 {
    using SafeERC20 for IERC20;

    address public immutable owner;
    address public operator;
    address public immutable treasury;

    IERC20  public immutable token;
    uint8   public immutable tokenDecimals;

    uint256 public ticketCostUnits;
    uint256 public ticketsSold;

    mapping(address => uint256) private ticketsByPlayer;
    address[] public players;

    uint256 public gameId;
    address[] public winners;

    event Enter(address indexed player, uint256 tickets, uint256 fee);
    event PoolBoosted(uint256 amountUnits);
    event TicketCostUpdated(uint256 newCostTokens, uint256 newCostUnits);
    event WinnerPicked(
        uint256 indexed gameId,
        address indexed winner,
        uint256 prize
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier onlyOwnerOrOperator() {
        require(
            msg.sender == owner || msg.sender == operator,
            "not owner/operator"
        );
        _;
    }

    constructor(
        IERC20 _token,
        address _treasury,
        uint256 _ticketCostTok
    ) {
        require(address(_token) != address(0), "token=0");
        require(_treasury != address(0), "treasury=0");
        require(_ticketCostTok > 0, "ticketCost=0");

        owner         = msg.sender;
        token         = _token;
        treasury      = _treasury;
        tokenDecimals = IERC20Metadata(address(_token)).decimals();

        ticketCostUnits = _toUnits(_ticketCostTok);
    }


    function setOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "operator=0");
        operator = _operator;
    }


    function ticketCostTokens() public view returns (uint256) {
        return ticketCostUnits / (10 ** tokenDecimals);
    }

    function currentPool() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function playersCount() external view returns (uint256) {
        return players.length;
    }

    function getPlayers() external view returns (address[] memory) {
        return players;
    }

    function getPlayerTickets(address addr) external view returns (uint256) {
        return ticketsByPlayer[addr];
    }

    function enter(uint256 amount) external {
        require(amount >= ticketCostUnits, "below ticket cost");
        require(amount % ticketCostUnits == 0, "not multiple of cost");

        uint256 ticketQty = amount / ticketCostUnits;
        token.safeTransferFrom(msg.sender, address(this), amount);

        uint256 fee = (amount * 20) / 100;
        token.safeTransfer(treasury, fee);

        if (ticketsByPlayer[msg.sender] == 0) {
            players.push(msg.sender);
        }
        ticketsByPlayer[msg.sender] += ticketQty;
        ticketsSold += ticketQty;

        emit Enter(msg.sender, ticketQty, fee);
    }


    function boostPool(uint256 amountUnits) external onlyOwnerOrOperator {
        token.safeTransferFrom(msg.sender, address(this), amountUnits);
        emit PoolBoosted(amountUnits);
    }

    function pickWinner() external onlyOwnerOrOperator {
        require(ticketsSold > 0, "no tickets sold");

        uint256 rand = _random() % ticketsSold;
        uint256 cursor;
        address winner;

        for (uint256 i = 0; i < players.length; i++) {
            cursor += ticketsByPlayer[players[i]];
            if (rand < cursor) {
                winner = players[i];
                break;
            }
        }
        require(winner != address(0), "winner not found");

        uint256 prize = token.balanceOf(address(this));
        token.safeTransfer(winner, prize);

        winners.push(winner);

        emit WinnerPicked(gameId, winner, prize);
        gameId += 1;

        _resetRound();
    }

    function updateTicketCost(uint256 newCostTokens) external onlyOwner {
        require(newCostTokens > 0, "cost=0");
        ticketCostUnits = _toUnits(newCostTokens);
        emit TicketCostUpdated(newCostTokens, ticketCostUnits);
    }

    function _resetRound() internal {
        for (uint256 i = 0; i < players.length; i++) {
            ticketsByPlayer[players[i]] = 0;
        }
        delete players;
        ticketsSold = 0;
    }

    function _toUnits(uint256 wholeTokens) internal view returns (uint256) {
        return wholeTokens * (10 ** tokenDecimals);
    }

    function _random() internal view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    block.prevrandao,
                    blockhash(block.number - 1),
                    ticketsSold,
                    address(this)
                )
            )
        );
    }
}
