import 'package:flutter/material.dart';
import '../models/profile_models.dart';
import 'profile_info_card.dart';

class RoleSpecificInfo extends StatelessWidget {
  final UserProfile profile;

  const RoleSpecificInfo({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    // Render based on user role
    if (profile is AdvocateProfile) {
      return _buildAdvocateInfo(profile as AdvocateProfile);
    } else if (profile is LawyerProfile) {
      return _buildLawyerInfo(profile as LawyerProfile);
    } else if (profile is ParalegalProfile) {
      return _buildParalegalInfo(profile as ParalegalProfile);
    } else if (profile is LawStudentProfile) {
      return _buildLawStudentInfo(profile as LawStudentProfile);
    } else if (profile is CitizenProfile) {
      return _buildCitizenInfo();
    }

    return const SizedBox.shrink();
  }

  Widget _buildAdvocateInfo(AdvocateProfile profile) {
    return Builder(
      builder: (context) => Column(
        children: [
          ProfileInfoCard(
            title: 'Professional Information',
            icon: Icons.work,
            children: [
              if (profile.rollNumber != null)
                _buildInfoRow(context, 'TLS Roll Number', profile.rollNumber!),
              if (profile.regionalChapter != null)
                _buildInfoRow(context, 'TLS Chapter',
                    '${profile.regionalChapter!.name} (${profile.regionalChapter!.code})'),
              if (profile.yearOfAdmissionToBar != null)
                _buildInfoRow(context, 'Year of Admission to Bar',
                    profile.yearOfAdmissionToBar.toString()),
              if (profile.yearsOfExperience != null)
                _buildInfoRow(context, 'Years of Experience',
                    '${profile.yearsOfExperience} years'),
              if (profile.practiceStatus != null)
                _buildInfoRow(context, 'Practice Status',
                    _formatPracticeStatus(profile.practiceStatus!)),
              if (profile.placeOfWork != null)
                _buildInfoRow(
                    context, 'Place of Work', profile.placeOfWork!.nameEn),
            ],
          ),
          if (profile.specializations != null &&
              profile.specializations!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ProfileInfoCard(
              title: 'Specializations',
              icon: Icons.school,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.specializations!
                      .map((spec) => Chip(
                            label: Text(spec.nameEn),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            labelStyle: const TextStyle(fontSize: 12),
                          ))
                      .toList(),
                ),
              ],
            ),
          ],
          if (profile.operatingRegions != null &&
              profile.operatingRegions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ProfileInfoCard(
              title: 'Operating Regions',
              icon: Icons.location_city,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.operatingRegions!
                      .map((region) => Chip(
                            label: Text(region.name),
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            labelStyle: const TextStyle(fontSize: 12),
                          ))
                      .toList(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLawyerInfo(LawyerProfile profile) {
    return Builder(
      builder: (context) => Column(
        children: [
          ProfileInfoCard(
            title: 'Professional Information',
            icon: Icons.work,
            children: [
              if (profile.yearsOfExperience != null)
                _buildInfoRow(context, 'Years of Experience',
                    '${profile.yearsOfExperience} years'),
              if (profile.placeOfWork != null)
                _buildInfoRow(
                    context, 'Place of Work', profile.placeOfWork!.nameEn),
            ],
          ),
          if (profile.specializations != null &&
              profile.specializations!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ProfileInfoCard(
              title: 'Specializations',
              icon: Icons.school,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.specializations!
                      .map((spec) => Chip(
                            label: Text(spec.nameEn),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            labelStyle: const TextStyle(fontSize: 12),
                          ))
                      .toList(),
                ),
              ],
            ),
          ],
          if (profile.operatingRegions != null &&
              profile.operatingRegions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ProfileInfoCard(
              title: 'Operating Regions',
              icon: Icons.location_city,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.operatingRegions!
                      .map((region) => Chip(
                            label: Text(region.name),
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            labelStyle: const TextStyle(fontSize: 12),
                          ))
                      .toList(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParalegalInfo(ParalegalProfile profile) {
    return Builder(
      builder: (context) => Column(
        children: [
          ProfileInfoCard(
            title: 'Professional Information',
            icon: Icons.work,
            children: [
              if (profile.yearsOfExperience != null)
                _buildInfoRow(context, 'Years of Experience',
                    '${profile.yearsOfExperience} years'),
              if (profile.placeOfWork != null)
                _buildInfoRow(
                    context, 'Place of Work', profile.placeOfWork!.nameEn),
            ],
          ),
          if (profile.operatingRegions != null &&
              profile.operatingRegions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ProfileInfoCard(
              title: 'Operating Regions',
              icon: Icons.location_city,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.operatingRegions!
                      .map((region) => Chip(
                            label: Text(region.name),
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            labelStyle: const TextStyle(fontSize: 12),
                          ))
                      .toList(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLawStudentInfo(LawStudentProfile profile) {
    return Builder(
      builder: (context) => ProfileInfoCard(
        title: 'Academic Information',
        icon: Icons.school,
        children: [
          if (profile.universityName != null)
            _buildInfoRow(context, 'University', profile.universityName!),
          if (profile.academicRole != null)
            _buildInfoRow(context, 'Role', profile.academicRole!.nameEn),
          if (profile.yearOfStudy != null)
            _buildInfoRow(
                context, 'Year of Study', 'Year ${profile.yearOfStudy}'),
        ],
      ),
    );
  }

  Widget _buildCitizenInfo() {
    return Builder(
      builder: (context) => Card(
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Citizen accounts have access to basic legal services and resources.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPracticeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'practising':
        return 'Practising';
      case 'non_practising':
        return 'Non-Practising';
      default:
        return status;
    }
  }
}
