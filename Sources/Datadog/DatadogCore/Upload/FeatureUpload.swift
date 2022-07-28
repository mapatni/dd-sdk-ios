/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

internal struct FeatureUpload {
    /// Uploads data to server.
    let uploader: DataUploadWorkerType

    init(
        featureName: String,
        context: DatadogV1Context,
        fileReader: Reader,
        requestBuilder: FeatureRequestBuilder,
        commonDependencies: FeaturesCommonDependencies
    ) {
        let uploadQueue = DispatchQueue(
            label: "com.datadoghq.ios-sdk-\(featureName)-upload",
            target: .global(qos: .utility)
        )

        let uploadConditions = DataUploadConditions(
            batteryStatus: commonDependencies.batteryStatusProvider
        )

        let dataUploader = DataUploader(
            httpClient: commonDependencies.httpClient,
            requestBuilder: requestBuilder
        )

        self.init(
            uploader: DataUploadWorker(
                queue: uploadQueue,
                fileReader: fileReader,
                dataUploader: dataUploader,
                context: context,
                uploadConditions: uploadConditions,
                delay: DataUploadDelay(performance: commonDependencies.performance),
                featureName: featureName
            )
        )
    }

    init(uploader: DataUploadWorkerType) {
        self.uploader = uploader
    }

    /// Flushes all authorised data and tears down the upload stack.
    /// - It completes all pending asynchronous work in upload worker and cancels its next schedules.
    /// - It flushes all data stored in authorized files by performing their arbitrary upload (without retrying).
    ///
    /// This method is executed synchronously. After return, the upload feature has no more
    /// pending asynchronous operations and all its authorized data should be considered uploaded.
    internal func flushAndTearDown() {
        uploader.cancelSynchronously()
        uploader.flushSynchronously()
    }
}