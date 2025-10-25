class RegistrationData {
  // Basic Information
  String email;
  String password;
  String passwordConfirm;
  String firstName;
  String lastName;
  DateTime? dateOfBirth;
  bool agreedToTerms;
  int userRole;
  String gender;
  String phoneNumber;

  // Optional Basic Fields
  String? idNumber;
  int? region;
  int? district;
  String? ward;

  // Professional Fields (for lawyers, advocates, etc.)
  String? rollNumber;
  int? regionalChapter;
  int? yearOfAdmissionToBar;
  int? placeOfWork;
  int? yearsOfExperience;
  String? practiceStatus;
  List<int>? specializations;
  String? officeAddress;
  List<int>? operatingRegions;
  List<int>? operatingDistricts;

  // Law Firm Fields
  String? firmName;
  int? managingPartner;
  int? numberOfLawyers;
  int? yearEstablished;
  String? website;

  // Academic Fields (for students, lecturers)
  String? institution;
  String? currentYearOfStudy;
  String? expectedGraduationYear;
  String? qualification;
  String? employerInstitution;
  String? areaOfLaw;

  RegistrationData({
    this.email = '',
    this.password = '',
    this.passwordConfirm = '',
    this.firstName = '',
    this.lastName = '',
    this.dateOfBirth,
    this.agreedToTerms = false,
    this.userRole = 0, // No role selected initially
    this.gender = '',
    this.phoneNumber = '',
    this.idNumber,
    this.region,
    this.district,
    this.ward,
    this.rollNumber,
    this.regionalChapter,
    this.yearOfAdmissionToBar,
    this.placeOfWork,
    this.yearsOfExperience,
    this.practiceStatus,
    this.specializations,
    this.officeAddress,
    this.operatingRegions,
    this.operatingDistricts,
    this.firmName,
    this.managingPartner,
    this.numberOfLawyers,
    this.yearEstablished,
    this.website,
    this.institution,
    this.currentYearOfStudy,
    this.expectedGraduationYear,
    this.qualification,
    this.employerInstitution,
    this.areaOfLaw,
  });

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {
      'email': email,
      'password': password,
      'password_confirm': passwordConfirm,
      'agreed_to_Terms': agreedToTerms,
      'user_role': userRole,
    };

    // Personal details - only for non-law firms (role != 5)
    if (userRole != 5) {
      data['first_name'] = firstName;
      data['last_name'] = lastName;
      data['gender'] = gender;
      data['phone_number'] = phoneNumber;
    }

    // Add optional fields only if they have values
    if (dateOfBirth != null) {
      data['date_of_birth'] = dateOfBirth!.toIso8601String().split('T')[0];
    }
    if (idNumber?.isNotEmpty == true) data['id_number'] = idNumber;
    if (region != null) data['region'] = region;
    if (district != null) data['district'] = district;
    if (ward?.isNotEmpty == true) data['ward'] = ward;

    // Professional fields
    if (rollNumber?.isNotEmpty == true) data['roll_number'] = rollNumber;
    if (regionalChapter != null) data['regional_chapter'] = regionalChapter;
    if (yearOfAdmissionToBar != null)
      data['year_of_admission_to_bar'] = yearOfAdmissionToBar;
    if (placeOfWork != null) data['place_of_work'] = placeOfWork;
    if (yearsOfExperience != null)
      data['years_of_experience'] = yearsOfExperience;
    if (practiceStatus?.isNotEmpty == true)
      data['practice_status'] = practiceStatus;
    if (specializations?.isNotEmpty == true)
      data['specializations'] = specializations;
    if (officeAddress?.isNotEmpty == true)
      data['office_address'] = officeAddress;
    if (operatingRegions?.isNotEmpty == true)
      data['operating_regions'] = operatingRegions;
    if (operatingDistricts?.isNotEmpty == true)
      data['operating_districts'] = operatingDistricts;

    // Law firm fields
    if (firmName?.isNotEmpty == true) data['firm_name'] = firmName;
    if (managingPartner != null) data['managing_partner'] = managingPartner;
    if (numberOfLawyers != null) data['number_of_lawyers'] = numberOfLawyers;
    if (yearEstablished != null) data['year_established'] = yearEstablished;
    if (website?.isNotEmpty == true) data['website'] = website;

    // Academic fields
    if (institution?.isNotEmpty == true) data['institution'] = institution;
    if (currentYearOfStudy?.isNotEmpty == true)
      data['current_year_of_study'] = currentYearOfStudy;
    if (expectedGraduationYear?.isNotEmpty == true)
      data['expected_graduation_year'] = expectedGraduationYear;
    if (qualification?.isNotEmpty == true)
      data['qualification'] = qualification;
    if (employerInstitution?.isNotEmpty == true)
      data['employer_institution'] = employerInstitution;
    if (areaOfLaw?.isNotEmpty == true) data['area_of_law'] = areaOfLaw;

    return data;
  }

  // Validation methods for different roles
  List<String> validateForRole() {
    List<String> errors = [];

    // Basic validation for all roles
    if (email.isEmpty) errors.add('Email is required');
    if (password.isEmpty) errors.add('Password is required');
    if (password != passwordConfirm) errors.add('Passwords do not match');
    if (!agreedToTerms) errors.add('You must agree to terms and conditions');

    // Personal details validation - NOT required for law firms (role 5)
    if (userRole != 5) {
      if (firstName.isEmpty) errors.add('First name is required');
      if (lastName.isEmpty) errors.add('Last name is required');
      if (dateOfBirth == null) errors.add('Date of birth is required');
      if (gender.isEmpty) errors.add('Gender is required');
      if (phoneNumber.isEmpty) errors.add('Phone number is required');
      if (region == null) errors.add('Region is required');
      if (district == null) errors.add('District is required');
    }

    // Role-specific validation
    switch (userRole) {
      case 2: // Advocate
        if (rollNumber?.isEmpty != false)
          errors.add('Roll number is required for advocates');
        if (regionalChapter == null)
          errors.add('Regional chapter is required for advocates');
        if (yearOfAdmissionToBar == null)
          errors.add('Year of admission to bar is required for advocates');
        if (practiceStatus?.isEmpty != false)
          errors.add('Practice status is required for advocates');
        break;
      case 1: // Lawyer
      case 3: // Paralegal
        if (placeOfWork == null) errors.add('Place of work is required');
        if (yearsOfExperience == null)
          errors.add('Years of experience is required');
        break;
      case 5: // Law Firm
        if (firmName?.isEmpty != false) errors.add('Firm name is required');
        if (managingPartner == null) errors.add('Managing partner is required');
        if (numberOfLawyers == null)
          errors.add('Number of lawyers is required');
        if (yearEstablished == null) errors.add('Year established is required');
        if (practiceStatus?.isEmpty != false)
          errors.add('Practice status is required');
        break;
    }

    return errors;
  }
}
