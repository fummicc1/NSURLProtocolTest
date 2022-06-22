import EasyFirebaseSwiftAuth
import EasyFirebaseSwiftFirestore
import Foundation
import Swinject

public class FirebaseAssembly: Assembly {
  public func assemble(container: Container) {
    container.register(FirestoreClient.self) { _ in
      FirestoreClient()
    }
    container.register(FirebaseAuthClient.self) { _ in
      FirebaseAuthClient()
    }
    container.register(AppleAuthClient.self) { _ in
      AppleAuthClient()
    }
  }
}
