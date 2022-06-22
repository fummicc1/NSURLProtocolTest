import EasyFirebaseSwiftFirestore
import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

extension Entity {
  struct User: FirestoreModel {
    enum Status: String, Codable {
      case signInAnonymously
      case signInWithApple
      case other
    }

    static var collectionName: String = FirestoreCollcetionName.users.rawValue
    static var singleIdentifier: String = collectionName
    static var arrayIdentifier: String = collectionName + "_array"

    var uid: String? {
      ref?.documentID
    }
    var status: Status
    @DocumentID
    var ref: DocumentReference?
    var acrhivedToiletsRef: CollectionReference? {
      ref?.collection(FirestoreCollcetionName.archivedToilets.rawValue)
    }
    var loggedInAt: Date?
    var signedUpAt: Date?
    @ServerTimestamp
    var createdAt: Timestamp?
    @ServerTimestamp
    var updatedAt: Timestamp?
    var homeToilet: HomeToilet?

    enum CodingKeys: String, CodingKey {
      case status
      case ref
      case loggedInAt
      case signedUpAt
      case updatedAt
      case createdAt
      case homeToilet
    }
  }
}
