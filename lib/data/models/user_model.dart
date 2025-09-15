class UserModel {
  final String? id;
  final String? surname;
  final String? names;
  final String? personalIdNumber;
  final DateTime? dateOfBirth;
  final String? sex;
  final String? chiefCode;
  final String? phoneNumber;
  final String? email;
  final String? idFrontImage;
  final String? idBackImage;
  final String? selfieImage;
  // final List<FingerprintData>? fingerprints;
  final VerificationStatus? verificationStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    this.id,
    this.surname,
    this.names,
    this.personalIdNumber,
    this.dateOfBirth,
    this.sex,
    this.chiefCode,
    this.phoneNumber,
    this.email,
    this.idFrontImage,
    this.idBackImage,
    this.selfieImage,
    // this.fingerprints,
    this.verificationStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'],
      surname: json['surname'],
      names: json['names'],
      personalIdNumber: json['personalIdNumber'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      sex: json['sex'],
      chiefCode: json['chiefCode'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      idFrontImage: json['idFrontImage'],
      idBackImage: json['idBackImage'],
      selfieImage: json['selfieImage'],
      // fingerprints: json['fingerprints'] != null
      //     ? (json['fingerprints'] as List)
      //         .map((e) => FingerprintData.fromJson(e))
      //         .toList()
      //     : null,
      verificationStatus: json['verificationStatus'] != null
          ? VerificationStatus.fromString(json['verificationStatus'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surname': surname,
      'names': names,
      'personalIdNumber': personalIdNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'sex': sex,
      'chiefCode': chiefCode,
      'phoneNumber': phoneNumber,
      'email': email,
      'idFrontImage': idFrontImage,
      'idBackImage': idBackImage,
      'selfieImage': selfieImage,
      // 'fingerprints': fingerprints?.map((e) => e.toJson()).toList(),
      'verificationStatus': verificationStatus?.value,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? surname,
    String? names,
    String? personalIdNumber,
    DateTime? dateOfBirth,
    String? sex,
    String? chiefCode,
    String? phoneNumber,
    String? email,
    String? idFrontImage,
    String? idBackImage,
    String? selfieImage,
    // List<FingerprintData>? fingerprints,
    VerificationStatus? verificationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      surname: surname ?? this.surname,
      names: names ?? this.names,
      personalIdNumber: personalIdNumber ?? this.personalIdNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      chiefCode: chiefCode ?? this.chiefCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      idFrontImage: idFrontImage ?? this.idFrontImage,
      idBackImage: idBackImage ?? this.idBackImage,
      selfieImage: selfieImage ?? this.selfieImage,
      // fingerprints: fingerprints ?? this.fingerprints,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// class FingerprintData {
//   final String finger;
//   final String template;
//   final double quality;
//   final DateTime capturedAt;

//   FingerprintData({
//     required this.finger,
//     required this.template,
//     required this.quality,
//     required this.capturedAt,
//   });

//   factory FingerprintData.fromJson(Map<String, dynamic> json) {
//     return FingerprintData(
//       finger: json['finger'],
//       template: json['template'],
//       quality: (json['quality'] ?? 0.0).toDouble(),
//       capturedAt: DateTime.parse(json['capturedAt']),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'finger': finger,
//       'template': template,
//       'quality': quality,
//       'capturedAt': capturedAt.toIso8601String(),
//     };
//   }
// }

enum VerificationStatus {
  pending('pending'),
  inProgress('in_progress'),
  verified('verified'),
  failed('failed'),
  manualReview('manual_review');

  final String value;
  const VerificationStatus(this.value);

  static VerificationStatus fromString(String value) {
    return VerificationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => VerificationStatus.pending,
    );
  }
}