pragma solidity 0.8.10;

import {Test} from "forge-std/Test.sol";
import {Siphon} from "contracts/Siphon.sol";
import {MakerVaultAdapter} from "contracts/adapters/dp/MakerVault.sol";
import {StablePoolAdapter} from "contracts/adapters/lp/balancer/StablePoolAdapter.sol";
import {TestAvatar} from "contracts/test/TestAvatar.sol";
import {Transaction} from "contracts/Transaction.sol";

import {DSProxy} from "contracts/test/maker/DssProxy.sol";
import {DssProxyActions} from "contracts/test/maker/DssProxyActions.sol";

contract TestSiphon is Test {
    Siphon siphon;
    TestAvatar avatar;
    MakerVaultAdapter makerVaultAdapter;
    StablePoolAdapter stablePoolAdapter;

    address constant gnosisDao = 0x0DA0C3e52C977Ed3cBc641fF02DD271c3ED55aFe;
    address constant daiWhale = 0xc08a8a9f809107c5A7Be6d90e315e4012c99F39a;

    address constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant tether = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address constant makerCdpManager =
        0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address constant makerDaiJoin = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address constant makerSpotter = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    DSProxy constant dsProxy =
        DSProxy(payable(0x7ef59064f4237dED8ce044f4db467957C5dbb9C9));
    DssProxyActions constant dsProxyActions =
        DssProxyActions(0x82ecD135Dce65Fbc6DbdD0e4237E0AF93FFD5038);

    address constant stableGauge = 0x34f33CDaED8ba0E1CEECE80e5f4a73bcf234cfac;
    address constant stablePool = 0x06Df3b2bbB68adc8B0e302443692037ED9f91b42;

    uint256 constant ratioTarget = 4586919454964052515806212538;
    uint256 constant ratioTrigger = 4211626045012448219058431512;
    uint256 constant vault = 28539;

    function setUp() public {
        vm.selectFork(vm.createFork(vm.envString("MAINNET_RPC_URL")));
        vm.rollFork(16_869_405);

        // deploy a new avatar
        avatar = new TestAvatar();

        // SET UP THE DP
        // make the avatar the owner of a preexisting CDP
        vm.prank(0x07499c08287A6cD6514cace69100916C67631dC7); // current vault owner
        dsProxy.setOwner(address(avatar));

        makerVaultAdapter = new MakerVaultAdapter(
            dai,
            makerCdpManager,
            makerDaiJoin,
            address(dsProxy),
            address(dsProxyActions),
            address(this),
            makerSpotter,
            ratioTarget,
            ratioTrigger,
            vault
        );

        // SETUP LP
        deal(dai, daiWhale, 1_000_000);
        deal(usdc, daiWhale, 1_000_000);
        deal(tether, daiWhale, 1_000_000);

        stablePoolAdapter = new StablePoolAdapter(
            address(this),
            address(avatar),
            stablePool,
            stableGauge,
            dai
        );

        // create and setup siphon
        siphon = new Siphon(address(this), address(avatar), address(this));
        avatar.setModule(address(siphon));
    }

    function test_One() public {
        uint256 delta = makerVaultAdapter.delta();
        emit log_named_uint("delta", delta);
        Transaction[] memory txs = makerVaultAdapter.paymentInstructions(delta);
        emit log_named_uint("txs.length", txs.length);

        for (uint i = 0; i < txs.length; i++) {
            vm.prank(gnosisDao);
            avatar.execTransactionFromModule(
                payable(txs[i].to),
                txs[i].value,
                txs[i].data,
                uint8(txs[i].operation)
            );
        }

        assert(siphon.avatar() == address(avatar));
    }
}
