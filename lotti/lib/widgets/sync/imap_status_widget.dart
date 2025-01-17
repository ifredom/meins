import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lotti/blocs/sync/imap/imap_state.dart';
import 'package:lotti/blocs/sync/imap/inbox_cubit.dart';
import 'package:lotti/widgets/misc/buttons.dart';

class ImapStatusWidget extends StatelessWidget {
  const ImapStatusWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InboxImapCubit, ImapState>(
        builder: (context, ImapState state) {
      return Column(
        children: [
          state.when(
            loading: () => const StatusTextWidget('loading'),
            connected: () => const StatusTextWidget('connected'),
            initial: () => const StatusTextWidget('initial'),
            loggedIn: () => const StatusTextWidget('logged in'),
            failed: (String error) =>
                StatusTextWidget('failed. reason: $error'),
            online: (DateTime lastUpdate) => Column(
              children: [
                StatusTextWidget('online, last update: $lastUpdate'),
                Button('reset offset',
                    onPressed: () =>
                        context.read<InboxImapCubit>().resetOffset(),
                    primaryColor: Colors.red),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class StatusTextWidget extends StatelessWidget {
  final String label;
  const StatusTextWidget(
    this.label, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'ShareTechMono',
        ),
      ),
    );
  }
}
