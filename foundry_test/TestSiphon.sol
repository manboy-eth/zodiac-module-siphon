pragma solidity 0.8.10;

import "forge-std/Test.sol";

import {Siphon} from "contracts/Siphon.sol";
import {MakerVaultAdapter} from "contracts/adapters/dp/MakerVault.sol";
import {StablePoolAdapter} from "contracts/adapters/lp/balancer/StablePoolAdapter.sol";
import {TestAvatar} from "contracts/test/TestAvatar.sol";
import {Transaction} from "contracts/Transaction.sol";
import {DSProxy} from "contracts/test/maker/DssProxy.sol";

import {SetupMakerVaultAdapter} from "foundry_test/util/SetupMakerVaultAdapter.sol";

// uppercase means that this are global contracts used by all CDPs and not specific to our vault

contract TestSiphon is Test, SetupMakerVaultAdapter {
    Siphon siphon;
    TestAvatar avatar;
    MakerVaultAdapter makerVaultAdapter;
    StablePoolAdapter stablePoolAdapter;

    address constant gnosisDao = 0x0DA0C3e52C977Ed3cBc641fF02DD271c3ED55aFe;
    address constant daiWhale = 0xc08a8a9f809107c5A7Be6d90e315e4012c99F39a;

    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant TETHER = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // DP: CDP/VAULT SPECIFIC
    DSProxy constant dsProxy =
        DSProxy(payable(0x7ef59064f4237dED8ce044f4db467957C5dbb9C9));
    uint256 constant vault = 28539;

    // DP: ADAPTER SPECIFIC
    uint256 constant ratioTarget = 4586919454964052515806212538;
    uint256 constant ratioTrigger = 4211626045012448219058431512;

    // LP:
    address constant BALANCER_STABLE_POOL_GAUGE =
        0x34f33CDaED8ba0E1CEECE80e5f4a73bcf234cfac; // Balancer staBAL3 Gauge Deposit (staBAL3-g...)
    address constant BALANCER_STABLE_POOL =
        0x06Df3b2bbB68adc8B0e302443692037ED9f91b42; // Balancer USD Stable Pool (staBAL3)

    function setUp() public {
        vm.selectFork(vm.createFork(vm.envString("MAINNET_RPC_URL")));
        vm.rollFork(16_869_405);

        // deploy a new avatar
        avatar = new TestAvatar();
        address adapterOwner = address(this);

        // DP: SET UP - START
        // make the avatar the owner of a preexisting CDP
        vm.prank(0x07499c08287A6cD6514cace69100916C67631dC7); // current vault owner
        dsProxy.setOwner(address(avatar));

        makerVaultAdapter = setupMakerDaoAdapter(
            DAI,
            address(dsProxy),
            vault,
            adapterOwner, // owner of the maker vault adapter (can set ratios etc.)
            ratioTarget,
            ratioTrigger
        );
        // DP:SET UP - END

        // LP: SET UP - START
        deal(BALANCER_STABLE_POOL, address(avatar), 1_000, true); // makes the avatar a LP in the balancer pool
        stablePoolAdapter = new StablePoolAdapter(
            adapterOwner, // can connect anf disconnect tubes
            address(avatar), // owner of the balancer pool
            BALANCER_STABLE_POOL,
            BALANCER_STABLE_POOL_GAUGE,
            DAI
        );
        // LP: SET UP - END

        // create and setup siphon
        siphon = new Siphon(address(this), address(avatar), address(this));
        avatar.setModule(address(siphon));
    }

    function test_connect_tube() public {
        siphon.connectTube(
            "testTube1",
            address(makerVaultAdapter),
            address(stablePoolAdapter)
        );

        uint256 delta = makerVaultAdapter.delta();
        emit log_named_uint("delta", delta);
        Transaction[] memory txs = makerVaultAdapter.paymentInstructions(delta);
        emit log_named_uint("txs.length", txs.length);

        // for (uint i = 0; i < txs.length; i++) {
        //     vm.prank(gnosisDao);
        //     avatar.execTransactionFromModule(
        //         payable(txs[i].to),
        //         txs[i].value,
        //         txs[i].data,
        //         uint8(txs[i].operation)
        //     );
        // }

        assert(siphon.avatar() == address(avatar));
    }
}
