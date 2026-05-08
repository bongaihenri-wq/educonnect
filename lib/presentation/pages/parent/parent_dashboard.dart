// lib/presentation/pages/parent/parent_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/theme.dart';
import '../../blocs/auth_bloc/auth_bloc.dart';
import 'widgets/parent_header.dart';
import 'widgets/child_card.dart';
import 'widgets/alerts_section.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/logout_button.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bisLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: const [
            // ✅ Les widgets sont DÉJÀ des slivers, pas de SliverToBoxAdapter ici !
            ParentHeader(),
            ChildCard(),
            AlertsSection(),
            QuickActionsGrid(),
            // ✅ LogoutButton doit être un sliver aussi
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: LogoutButton(),
              ),
            ),
            SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }
}