//
//  ReadableFileStream.swift
//  Suv
//
//  Created by Yuki Takei on 6/12/16.
//
//

public class ReadableFileStream: AsyncReceivingStream {
    
    public let path: String
    
    public let mode: Int32
    
    public let flags: FileMode
    
    public var closed = false
    
    private var fd: Int32? = nil
    
    public init(path: String, flags: FileMode = .read, mode: Int32 = FileMode.read.defaultPermission){
        self.path = path
        self.flags = flags
        self.mode = mode
    }
    
    public func receive(upTo byteCount: Int = 1024, timingOut deadline: Double = .never, completion: @escaping ((Void) throws -> Data) -> Void = { _ in }) {
        if closed {
            completion {
                throw ClosableError.alreadyClosed
            }
            return
        }
        
        openIfNeeded { [unowned self] result in
            do {
                try result()
                FS.read(self.fd!, completion: completion)
            } catch {
                completion {
                    throw error
                }
            }
        }
    }
    
    private func openIfNeeded(_ callback: @escaping ((Void) throws -> Void) -> Void){
        if fd != nil {
            callback { }
        } else {
            FS.open(path, flags: flags, mode: mode) { [unowned self] getfd in
                callback {
                    self.fd = try getfd()
                }
            }
        }
    }
    
    public func flush(timingOut deadline: Double = .never, completion: @escaping ((Void) throws -> Void) -> Void = {_ in}) {
        // noop
    }
    
    public func close() throws {    
        if closed {
            throw ClosableError.alreadyClosed
        }
        if let fd = fd {
            FS.close(fd)
        }
        closed = true
    }
}
