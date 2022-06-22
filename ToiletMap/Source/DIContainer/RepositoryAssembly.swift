import EasyFirebaseSwiftAuth
import EasyFirebaseSwiftFirestore
import Foundation
import Swinject

public class RepositoryAssembly: Assembly {
  public func assemble(container: Container) {
    container.register(AuthRepositoryType.self) { resolver in
      let toiletRepository = resolver.resolve(ToiletRepositoryType.self)!
      let dependency = AuthRepository.Dependency(
        auth: resolver.resolve(AppleAuthClient.self)!,
        firAuth: resolver.resolve(FirebaseAuthClient.self)!
      )
      return AuthRepository(
        toiletRepository: toiletRepository,
        dependency: dependency
      )
    }

    container.register(UserRepositoryType.self) { resolver in
      return UserRepository(
        firestoreClient: resolver.resolve(FirestoreClient.self)!,
        authClient: resolver.resolve(FirebaseAuthClient.self)!
      )
    }

    container.register(ToiletRepositoryType.self) { resolver in
      return ToiletRepository(
        userRepository: container.resolve(UserRepositoryType.self)!,
        firestore: container.resolve(FirestoreClient.self)!,
        auth: container.resolve(FirebaseAuthClient.self)!
      )
    }

    container.register(MapItemRepositoryType.self) { resolver in
      return MapItemRepository(
        firestore: container.resolve(FirestoreClient.self)!
      )
    }

    container.register(ReviewRepositoryType.self) { resolver in
      return ReviewRepository(
        firestore: container.resolve(FirestoreClient.self)!
      )
    }

    container.register(ToiletDiaryRepositoryType.self) { resolver in
      return ToiletDiaryRepository(
        firestore: resolver.resolve(FirestoreClient.self)!,
        auth: resolver.resolve(FirebaseAuthClient.self)!
      )
    }
  }
}
