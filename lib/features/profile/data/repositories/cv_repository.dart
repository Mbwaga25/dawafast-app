import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/api_client.dart';
import '../models/cv_model.dart'; // Ensure it exists or import what's needed
import '../models/cv_model.dart';

final cvRepositoryProvider = Provider((ref) => CVRepository());

class CVRepository {
  static const String _getMyCVDataQuery = r'''
    query GetMyCVData {
      users {
        myEducation {
          id
          degree
          institution
          fieldOfStudy
          startYear
          endYear
          description
        }
        myWorkExperiences {
          id
          position
          organization
          location
          startDate
          endDate
          isCurrent
          description
        }
        myCertifications {
          id
          name
          issuingOrganization
          issueDate
          expiryDate
          credentialId
          credentialUrl
        }
        mySkills {
          id
          name
          proficiencyLevel
          yearsOfExperience
        }
        myPublications {
          id
          title
          journalOrConference
          publicationYear
          authors
          doi
          url
          abstract
        }
        myProfessionalProfile {
          id
          bio
          yearsOfExperience
          languages
          availabilityStatus
          consultationFee
        }
      }
    }
  ''';

  static const String _updateProfessionalProfileMutation = r'''
    mutation UpdateProfessionalProfile(
      $bio: String
      $yearsOfExperience: Int
      $languages: String
      $availabilityStatus: String
      $consultationFee: Decimal
    ) {
      users {
        updateProfessionalProfile(
          bio: $bio
          yearsOfExperience: $yearsOfExperience
          languages: $languages
          availabilityStatus: $availabilityStatus
          consultationFee: $consultationFee
        ) {
          success
          errors
          profile {
            id
            bio
            yearsOfExperience
            languages
            availabilityStatus
            consultationFee
          }
        }
      }
    }
  ''';

  static const String _createEducationMutation = r'''
    mutation CreateEducation($degree: String!, $institution: String!, $fieldOfStudy: String!, $startYear: Int!, $endYear: Int, $description: String) {
      users {
        createEducation(degree: $degree, institution: $institution, fieldOfStudy: $fieldOfStudy, startYear: $startYear, endYear: $endYear, description: $description) {
          success
          errors
          education { id degree institution fieldOfStudy startYear endYear description }
        }
      }
    }
  ''';

  static const String _deleteEducationMutation = r'''
    mutation DeleteEducation($id: ID!) {
      users {
        deleteEducation(id: $id) { success errors }
      }
    }
  ''';

  static const String _createWorkExperienceMutation = r'''
    mutation CreateWorkExperience($position: String!, $organization: String!, $location: String!, $startDate: Date!, $endDate: Date, $isCurrent: Boolean, $description: String) {
      users {
        createWorkExperience(position: $position, organization: $organization, location: $location, startDate: $startDate, endDate: $endDate, isCurrent: $isCurrent, description: $description) {
          success
          errors
          experience { id position organization location startDate endDate isCurrent description }
        }
      }
    }
  ''';

  static const String _deleteWorkExperienceMutation = r'''
    mutation DeleteWorkExperience($id: ID!) {
      users {
        deleteWorkExperience(id: $id) { success errors }
      }
    }
  ''';

  static const String _createCertificationMutation = r'''
    mutation CreateCertification($name: String!, $issuingOrganization: String!, $issueDate: Date!, $expiryDate: Date, $credentialId: String, $credentialUrl: String) {
      users {
        createCertification(name: $name, issuingOrganization: $issuingOrganization, issueDate: $issueDate, expiryDate: $expiryDate, credentialId: $credentialId, credentialUrl: $credentialUrl) {
          success
          errors
          certification { id name issuingOrganization issueDate expiryDate credentialId credentialUrl }
        }
      }
    }
  ''';

  static const String _deleteCertificationMutation = r'''
    mutation DeleteCertification($id: ID!) {
      users {
        deleteCertification(id: $id) { success errors }
      }
    }
  ''';

  static const String _createSkillMutation = r'''
    mutation CreateSkill($name: String!, $proficiencyLevel: String, $yearsOfExperience: Int) {
      users {
        createSkill(name: $name, proficiencyLevel: $proficiencyLevel, yearsOfExperience: $yearsOfExperience) {
          success
          errors
          skill { id name proficiencyLevel yearsOfExperience }
        }
      }
    }
  ''';

  static const String _deleteSkillMutation = r'''
    mutation DeleteSkill($id: ID!) {
      users {
        deleteSkill(id: $id) { success errors }
      }
    }
  ''';

  Future<Map<String, dynamic>> fetchCVData() async {
    final QueryOptions options = QueryOptions(
      document: gql(_getMyCVDataQuery),
      fetchPolicy: FetchPolicy.noCache,
    );

    final QueryResult result = await ApiClient.client.value.query(options);
    if (result.hasException) throw result.exception!;
    return result.data?['users'] ?? {};
  }

  Future<bool> updateProfessionalProfile({
    String? bio,
    int? yearsOfExperience,
    String? languages,
    String? availabilityStatus,
    double? consultationFee,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(_updateProfessionalProfileMutation),
      variables: {
        if (bio != null) 'bio': bio,
        if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
        if (languages != null) 'languages': languages,
        if (availabilityStatus != null) 'availabilityStatus': availabilityStatus,
        if (consultationFee != null) 'consultationFee': consultationFee,
      },
    );

    final QueryResult result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    return result.data?['users']?['updateProfessionalProfile']?['success'] ?? false;
  }

  // --- CV ADD/DELETE METHODS ---

  Future<bool> addEducation({required String degree, required String institution, required String fieldOfStudy, required int startYear, int? endYear, String? description}) async {
    final options = MutationOptions(document: gql(_createEducationMutation), variables: {'degree': degree, 'institution': institution, 'fieldOfStudy': fieldOfStudy, 'startYear': startYear, 'endYear': endYear, 'description': description});
    final result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    return result.data?['users']?['createEducation']?['success'] ?? false;
  }

  Future<bool> deleteEducation(String id) async {
    final options = MutationOptions(document: gql(_deleteEducationMutation), variables: {'id': id});
    final result = await ApiClient.client.value.mutate(options);
    return result.data?['users']?['deleteEducation']?['success'] ?? false;
  }

  Future<bool> addWorkExperience({required String position, required String organization, required String location, required DateTime startDate, DateTime? endDate, bool isCurrent = false, String? description}) async {
    final options = MutationOptions(document: gql(_createWorkExperienceMutation), variables: {'position': position, 'organization': organization, 'location': location, 'startDate': DateFormat('yyyy-MM-dd').format(startDate), 'endDate': endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : null, 'isCurrent': isCurrent, 'description': description});
    final result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    return result.data?['users']?['createWorkExperience']?['success'] ?? false;
  }

  Future<bool> deleteWorkExperience(String id) async {
    final options = MutationOptions(document: gql(_deleteWorkExperienceMutation), variables: {'id': id});
    final result = await ApiClient.client.value.mutate(options);
    return result.data?['users']?['deleteWorkExperience']?['success'] ?? false;
  }

  Future<bool> addCertification({required String name, required String issuingOrganization, required DateTime issueDate, DateTime? expiryDate, String? credentialId, String? credentialUrl}) async {
    final options = MutationOptions(document: gql(_createCertificationMutation), variables: {'name': name, 'issuingOrganization': issuingOrganization, 'issueDate': DateFormat('yyyy-MM-dd').format(issueDate), 'expiryDate': expiryDate != null ? DateFormat('yyyy-MM-dd').format(expiryDate) : null, 'credentialId': credentialId, 'credentialUrl': credentialUrl});
    final result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    return result.data?['users']?['createCertification']?['success'] ?? false;
  }

  Future<bool> deleteCertification(String id) async {
    final options = MutationOptions(document: gql(_deleteCertificationMutation), variables: {'id': id});
    final result = await ApiClient.client.value.mutate(options);
    return result.data?['users']?['deleteCertification']?['success'] ?? false;
  }

  Future<bool> addSkill({required String name, String proficiencyLevel = 'intermediate', int? yearsOfExperience}) async {
    final options = MutationOptions(document: gql(_createSkillMutation), variables: {'name': name, 'proficiencyLevel': proficiencyLevel, 'yearsOfExperience': yearsOfExperience});
    final result = await ApiClient.client.value.mutate(options);
    if (result.hasException) throw result.exception!;
    return result.data?['users']?['createSkill']?['success'] ?? false;
  }

  Future<bool> deleteSkill(String id) async {
    final options = MutationOptions(document: gql(_deleteSkillMutation), variables: {'id': id});
    final result = await ApiClient.client.value.mutate(options);
    return result.data?['users']?['deleteSkill']?['success'] ?? false;
  }
}

final myCVDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(cvRepositoryProvider);
  return repository.fetchCVData();
});
