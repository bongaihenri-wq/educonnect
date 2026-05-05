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
          slivers: [
            const ParentHeader(),
            const ChildCard(),
            const AlertsSection(),
            const QuickActionsGrid(),
            const LogoutButton(),
            const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
          ],
        ),
      ),
    );
  }
}