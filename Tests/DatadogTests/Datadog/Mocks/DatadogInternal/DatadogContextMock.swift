/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

@testable import Datadog

extension DatadogContext: AnyMockable {
    static func mockAny() -> DatadogContext { mockWith() }

    static func mockWith(
        site: DatadogSite? = .mockAny(),
        clientToken: String = .mockAny(),
        service: String = .mockAny(),
        env: String = .mockAny(),
        version: String = .mockAny(),
        source: String = .mockAny(),
        sdkVersion: String = .mockAny(),
        ciAppOrigin: String? = .mockAny(),
        serverTimeOffset: TimeInterval = .zero,
        applicationName: String = .mockAny(),
        applicationBundleIdentifier: String = .mockAny(),
        sdkInitDate: Date = .mockRandomInThePast(),
        device: DeviceInfo = .mockAny(),
        networkConnectionInfo: NetworkConnectionInfo = .mockAny(),
        carrierInfo: CarrierInfo? = .mockAny()
    ) -> DatadogContext {
        .init(
            site: site,
            clientToken: clientToken,
            service: service,
            env: env,
            version: version,
            source: source,
            sdkVersion: sdkVersion,
            ciAppOrigin: ciAppOrigin,
            serverTimeOffset: serverTimeOffset,
            applicationName: applicationName,
            applicationBundleIdentifier: applicationBundleIdentifier,
            sdkInitDate: sdkInitDate,
            device: device,
            networkConnectionInfo: networkConnectionInfo,
            carrierInfo: carrierInfo
        )
    }
}