//
//  ThreeCommasConfig.swift
//  CSAI1
//
//  Created by DM on 4/1/25.
//


struct ThreeCommasConfig {
    // Read-Only Key (for fetching live data, portfolio info, etc.)
    static let readOnlyAPIKey = "5e8835b1dc0c4ac29fa79e30e701c05d9cb5f7671dce4ad0be8fb28d76400faa"
    static let readOnlySecret = "4fd3132428ad2e51cddd76967b6c8874f12114ce24037b05fb5f6334d734d5e354846d374440b0642f7c0ab238a7414d6a0d622e6abee12d834a39e9caa133a01210cae0d0bd1fa664ffc8b2378c1e60f7ab877b45dfef1f89894089b8ec8fdebbf0376d"
    
    // Trading Key (for actions that modify data, like starting/stopping bots or placing trades)
    static let tradingAPIKey = "eaef64c211e24e9b8d0a02bf7f37a8307a70c86e004a4df8918454e3f4411410"
    static let tradingSecret = "c9033b1c470514a4c8e251a42c3fd4f18f595436a9668c39c6bcb7848d41b9af4d3785677627ac001b8f1213198c7a0b36bce4a9f8c499a4868b82ddacc2179b9b501eb3a88822119c5b6db19f38ae7b0528babc652a4a72191b8f06e7bbd9de6f308ee6"
}