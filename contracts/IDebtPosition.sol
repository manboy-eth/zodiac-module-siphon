// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.6;

interface IDebtPosition {
    function assetDebt() external view returns (address);

    function setRatioTrigger(uint256 ratio) external;

    function setRatioTarget(uint256 ratio) external;

    function ratio() external view returns (uint256);

    function ratioTrigger() external view returns (uint256);

    function ratioTarget() external view returns (uint256);

    function delta() external view returns (uint256 amount);

    function paymentInstructions(uint256 amount)
        external
        view
        returns (
            address,
            uint256,
            bytes memory
        );
}
