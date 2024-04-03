//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 02.01.2024.
//

import XCTest
import StoreKit
@testable import OnboardingPaymentKit

final class OPSReceiptValidatorTests: XCTestCase {
    
    private var mockFetcher: MockOPSReceiptFetcher!
    private var receiptValidator: OPSReceiptValidator!
    
    override func setUp() async throws {
        mockFetcher = MockOPSReceiptFetcher()
        receiptValidator = OPSReceiptValidator(sharedSecret: "", fetcher: mockFetcher)
    }
    
    func testNetworkError() async {
        let networkError = NSError(domain: "network", code: 401)
        let receiptError: ReceiptError = .networkError(error: networkError)
        mockFetcher.result = .failure(receiptError)
        await validateReceiptAndValidateError(receiptError)
    }
    
    func testNoDataError() async {
        let receiptError: ReceiptError = .noRemoteData
        mockFetcher.result = .failure(receiptError)
        await validateReceiptAndValidateError(receiptError)
    }
    
    func testUnknownDecodingError() async {
        let receiptError: ReceiptError = .jsonDecodeError(string: "")
        mockFetcher.result = .success(Data())
        await validateReceiptAndValidateError(receiptError)
    }
    
    func testKnownUnhandledDecodingError() async throws {
        let status = 666 // Not-known error type code
        try setWrongReceiptErrorWith(code: status)
        let receiptError: ReceiptError = createReceiptDecodeError(status: status)
        await validateReceiptAndValidateError(receiptError)
    }
    
    func testShouldBeProductionEnvWhenSandboxSet() async throws {
        let status = ReceiptStatus.productionEnvironment
        try setWrongReceiptErrorWith(status: status)
        receiptValidator.environment = .sandbox
        let receiptError: ReceiptError = createReceiptDecodeError(status: status.rawValue)
        await validateReceiptAndValidateError(receiptError,
                                              numberOfCalls: 2)
    }
    
    func testShouldBeProductionEnvWhenProductionSet() async throws {
        let status = ReceiptStatus.productionEnvironment
        try setWrongReceiptErrorWith(status: status)
        receiptValidator.environment = .production
        let receiptError: ReceiptError = createReceiptDecodeError(status: status.rawValue)
        await validateReceiptAndValidateError(receiptError,
                                              numberOfCalls: 1)
    }
    
    func testShouldBeSandboxEnvWhenProductionSet() async throws {
        let status = ReceiptStatus.testReceipt
        try setWrongReceiptErrorWith(status: status)
        receiptValidator.environment = .production
        let receiptError: ReceiptError = createReceiptDecodeError(status: status.rawValue)
        await validateReceiptAndValidateError(receiptError,
                                              numberOfCalls: 2)
    }
    
    func testShouldBeSandboxEnvWhenSandboxSet() async throws {
        let status = ReceiptStatus.testReceipt
        try setWrongReceiptErrorWith(status: status)
        receiptValidator.environment = .sandbox
        let receiptError: ReceiptError = createReceiptDecodeError(status: status.rawValue)
        await validateReceiptAndValidateError(receiptError,
                                              numberOfCalls: 1)
    }
  
    func testValidReceiptWithInvalidStatus() async throws {
        let status = ReceiptStatus.userAccountCanNotBeFound
        try setReceiptResponseWith(status: status.rawValue)
        let receiptError: ReceiptError = .receiptInvalid(status: status)
        await validateReceiptAndValidateError(receiptError)
    }
    
    func testValidReceipt() async throws {
        let status = ReceiptStatus.valid
        let receipt = try setReceiptResponseWith(status: status.rawValue)
        let response = try await receiptValidator.validate(appStoreReceiptData: Data())
        XCTAssertEqual(receipt, response)
    }
}

// MARK: - Private methods
private extension OPSReceiptValidatorTests {
    func validateReceiptAndValidateError(_ receiptError: ReceiptError,
                                         numberOfCalls: Int = 1) async {
        do {
            let _ = try await receiptValidator.validate(appStoreReceiptData: Data())
            fatalError("Should throw error")
        } catch let error as ReceiptError {
            XCTAssertEqual(error, receiptError)
            XCTAssertEqual(numberOfCalls, mockFetcher.numberOfCalls)
        } catch {
            fatalError("Should throw ReceiptError")
        }
    }
    
    func createReceiptEntityWith(status: Int) -> AppStoreValidatedReceipt {
        AppStoreValidatedReceipt(status: status,
                                 environment: "",
                                 receipt: .init(receiptType: "",
                                                appItemId: 0,
                                                receiptCreationDateMs: "",
                                                inApp: nil),
                                 latestReceipt: nil,
                                 pendingRenewalInfo: nil,
                                 latestReceiptInfo: nil)
    }
    
    @discardableResult
    func setReceiptResponseWith(status: Int) throws -> AppStoreValidatedReceipt {
        let receipt = createReceiptEntityWith(status: status)
        try setReceiptResponse(receipt)
        return receipt
    }
    
    func setReceiptResponse(_ receipt: AppStoreValidatedReceipt) throws {
        try setEncodableFetcherResult(receipt)
    }
    
    func createReceiptDecodeError(status: Int) -> ReceiptError {
        .jsonDecodeError(string: "{\"status\":\(status)}")
    }
    
    func setWrongReceiptErrorWith(status: ReceiptStatus) throws {
        try setWrongReceiptErrorWith(code: status.rawValue)
    }
    
    func setWrongReceiptErrorWith(code: Int) throws {
        let receipt = AppStoreWrongReceipt(status: code)
        try setEncodableFetcherResult(receipt)
    }
    
    func setEncodableFetcherResult(_ object: Encodable) throws {
        let data = try JSONEncoder().encode(object)
        mockFetcher.result = .success(data)
    }
}

private final class MockOPSReceiptFetcher: OPSReceiptFetcher {
    
    var numberOfCalls = 0
    var result: Result<Data, OnboardingPaymentKit.ReceiptError>!
    
    func fetchReceipt(appStoreReceiptData: Data, 
                      sharedSecret: String,
                      environment: OnboardingPaymentKit.PaymentsEnvironment,
                      completion: @escaping ((Result<Data, OnboardingPaymentKit.ReceiptError>) -> ())) {
        numberOfCalls += 1
        completion(result)
    }
}
