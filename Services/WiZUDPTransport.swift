import Foundation
import Network

protocol LightTransport: Sendable {
    func send(_ payload: Data, toIPv4 address: String) async throws
}

enum TransportError: LocalizedError {
    case invalidIPv4
    case timeout
    case connectionFailed
    var errorDescription: String? {
        switch self {
        case .invalidIPv4: "Enter a valid IPv4 address for the bulb."
        case .timeout: "WiZ UDP command timed out."
        case .connectionFailed: "Could not send WiZ UDP command."
        }
    }
}

struct WiZUDPTransport: LightTransport {
    private let port: NWEndpoint.Port = 38899

    func send(_ payload: Data, toIPv4 address: String) async throws {
        guard IPv4Validator.isValid(address) else { throw TransportError.invalidIPv4 }
        let connection = NWConnection(host: NWEndpoint.Host(address), port: port, using: .udp)
        let queue = DispatchQueue(label: "wiz.udp.\(UUID().uuidString)")
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let lock = NSLock()
            var finished = false
            func finish(_ result: Result<Void, Error>) {
                lock.lock()
                let shouldResume = !finished
                if shouldResume { finished = true }
                lock.unlock()
                guard shouldResume else { return }
                connection.stateUpdateHandler = nil
                connection.cancel()
                continuation.resume(with: result)
            }
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.send(content: payload, completion: .contentProcessed { error in
                        if let error { finish(.failure(error)) }
                        else { finish(.success(())) }
                    })
                case .failed(let error): finish(.failure(error))
                case .cancelled: finish(.failure(TransportError.connectionFailed))
                default: break
                }
            }
            connection.start(queue: queue)
            queue.asyncAfter(deadline: .now() + 3) { finish(.failure(TransportError.timeout)) }
        }
    }
}

enum IPv4Validator {
    static func isValid(_ input: String) -> Bool {
        let parts = input.split(separator: ".", omittingEmptySubsequences: false)
        return parts.count == 4 && parts.allSatisfy { part in
            guard !part.isEmpty, part.count <= 3,
                  part.allSatisfy({ $0.isASCII && $0.isNumber }),
                  let n = UInt8(part) else { return false }
            return String(n) == part
        }
    }
}
