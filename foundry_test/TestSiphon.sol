pragma solidity 0.8.10;

import {Test} from "forge-std/Test.sol";
import {Siphon} from "contracts/Siphon.sol";
import {MakerVaultAdapter} from "contracts/adapters/dp/MakerVault.sol";
import {TestAvatar} from "contracts/test/TestAvatar.sol";

import {DSProxy} from "contracts/test/maker/DssProxy.sol";
import {DssProxyActions} from "contracts/test/maker/DssProxyActions.sol";

contract TestSiphon is Test {
    Siphon siphon;
    TestAvatar avatar;
    MakerVaultAdapter makerVaultAdapter;

    address constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant makerCdpManager =
        0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address constant makerDaiJoin = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address constant makerSpotter = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    DSProxy dsProxy;
    DssProxyActions dsProxyActions;

    uint256 constant ratioTarget = 4586919454964052515806212538;
    uint256 constant ratioTrigger = 4211626045012448219058431512;
    uint256 constant vault = 123;

    function setUp() public {
        vm.selectFork(vm.createFork(vm.envString("MAINNET_RPC_URL")));

        avatar = new TestAvatar();
        siphon = new Siphon(address(this), address(avatar), address(this));
        avatar.setModule(address(siphon));

        dsProxy = new DSProxy(address(avatar));
        dsProxyActions = new DssProxyActions();

        address owner = address(this);

        makerVaultAdapter = new MakerVaultAdapter(
            dai,
            makerCdpManager,
            makerDaiJoin,
            address(dsProxy),
            address(dsProxyActions),
            owner,
            makerSpotter,
            ratioTarget,
            ratioTrigger,
            vault
        );
    }

    function test_One() public view {
        assert(siphon.avatar() == address(avatar));
    }
}
