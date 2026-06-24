// lib/presentation/widgets/update_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final VersionCheckResult update;
  final VoidCallback? onDismiss;
  final bool isBlocking;

  const UpdateDialog({
    super.key,
    required this.update,
    this.onDismiss,
    this.isBlocking = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return WillPopScope(
      onWillPop: () async => !isBlocking && !update.isMandatory,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Container(
          width: 0.85.sw,
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec icône
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.system_update,
                      color: primaryColor,
                      size: 32.w,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mise à jour disponible',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'v${update.versionName}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // Badge obligatoire si applicable
              if (update.isMandatory) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red, size: 20.w),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Cette mise à jour est obligatoire pour continuer.',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
              ],

              // Taille du fichier
              if (update.fileSize != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.storage, size: 16.w, color: Colors.grey[600]),
                      SizedBox(width: 6.w),
                      Text(
                        'Taille: ${UpdateService.formatFileSize(update.fileSize)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 16.h),

              // Changelog
              if (update.changelog != null && update.changelog!.isNotEmpty) ...[
                Text(
                  'Nouveautés :',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    update.changelog!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      height: 1.5,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],

              // Boutons d'action
              Row(
                children: [
                  if (!update.isMandatory && !isBlocking)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onDismiss?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Plus tard',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                    ),
                  if (!update.isMandatory && !isBlocking)
                    SizedBox(width: 12.w),
                  Expanded(
                    flex: update.isMandatory || isBlocking ? 2 : 1,
                    child: ElevatedButton.icon(
                      onPressed: () => _onDownload(context),
                      icon: Icon(Icons.download, size: 20.w),
                      label: Text(
                        'Télécharger',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onDownload(BuildContext context) async {
    final service = UpdateService();
    
    // Incrémenter le compteur
    if (update.versionId != null) {
      await service.incrementDownloadCount(update.versionId!);
    }

    final uri = Uri.parse(update.apkUrl!);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'ouvrir le lien de téléchargement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}