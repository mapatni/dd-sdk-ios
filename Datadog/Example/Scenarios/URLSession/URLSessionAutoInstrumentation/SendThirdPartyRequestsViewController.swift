/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import UIKit
import Datadog

internal class SendThirdPartyRequestsViewController: UIViewController {
    private var testScenario: URLSessionBaseScenario!
    private lazy var session = URLSession(
        configuration: .default,
        delegate: DDURLSessionDelegate(),
        delegateQueue: nil
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        self.testScenario = (appConfiguration.testScenario as! URLSessionBaseScenario)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        callThirdPartyURL()
        callThirdPartyURLRequest()
    }

    private func callThirdPartyURL() {
        let task = session.dataTask(with: testScenario.thirdPartyURL)
        task.resume()
    }

    private func callThirdPartyURLRequest() {
        let task = session.dataTask(with: testScenario.thirdPartyRequest)
        task.resume()
    }
}