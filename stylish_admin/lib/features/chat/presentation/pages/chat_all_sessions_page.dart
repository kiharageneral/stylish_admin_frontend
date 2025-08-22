import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stylish_admin/core/theme/theme.dart';
import 'package:stylish_admin/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:stylish_admin/features/chat/presentation/pages/chat_sesson_detail_page.dart';
import 'package:stylish_admin/features/chat/presentation/widgets/chat_session_card.dart';

class ChatAllSessionsPage extends StatefulWidget {
  const ChatAllSessionsPage({super.key});

  @override
  State<ChatAllSessionsPage> createState() => _ChatAllSessionsPageState();
}

class _ChatAllSessionsPageState extends State<ChatAllSessionsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(const GetChatSessions());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<ChatBloc>().add(GetMoreChatSessions());
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _refreshSessions() async {
    context.read<ChatBloc>().add(const GetChatSessions(isRefresh: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryLight,
      appBar: AppBar(
        title: const Text('All Chat Sessions'),
        backgroundColor: AppTheme.cardBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        titleTextStyle: AppTheme.headingMedium().copyWith(
          color: AppTheme.textPrimary,
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSessions,
        child: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state.status == ChatStatus.loading && state.sessions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == ChatStatus.failure && state.sessions.isEmpty) {
              return Center(
                child: Text(
                  'Error loading sessions: ${state.error?.message ?? 'Unknown Error'}',
                ),
              );
            }

            if (state.sessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No chat sessions found.',
                      style: AppTheme.bodyLarge(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pull down to refresh.',
                      style: AppTheme.bodyMedium().copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: state.hasMoreSessions
                  ? state.sessions.length + 1
                  : state.sessions.length,

              itemBuilder: (context, index) {
                if (index >= state.sessions.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final session = state.sessions[index];
                return ChatSessionCard(
                  session: session,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatSessonDetailPage(sessionId: session.sessionId),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
