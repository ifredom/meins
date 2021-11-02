import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:wisely/blocs/audio/player_cubit.dart';
import 'package:wisely/blocs/audio/recorder_cubit.dart';
import 'package:wisely/blocs/journal_entities_cubit.dart';
import 'package:wisely/blocs/sync/encryption_cubit.dart';
import 'package:wisely/blocs/sync/imap_cubit.dart';
import 'package:wisely/pages/audio.dart';
import 'package:wisely/pages/editor.dart';
import 'package:wisely/pages/health.dart';
import 'package:wisely/pages/journal.dart';
import 'package:wisely/pages/photo_import.dart';
import 'package:wisely/pages/settings.dart';
import 'package:wisely/sync/secure_storage.dart';
import 'package:wisely/theme.dart';

import 'blocs/journal/journal_cubit.dart';
import 'blocs/sync/outbound_queue_cubit.dart';
import 'blocs/sync/vector_clock_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );
  runApp(const WiselyApp());
  // Bloc.observer = MyBlocObserver();
}

class WiselyApp extends StatefulWidget {
  const WiselyApp({Key? key}) : super(key: key);

  @override
  _WiselyAppState createState() => _WiselyAppState();
}

class _WiselyAppState extends State<WiselyApp> {
  late StreamSubscription _intentDataStreamSubscription;
  List<SharedMediaFile>? _sharedFiles;
  String? _sharedText;

  @override
  void initState() {
    super.initState();

    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream()
        .listen((List<SharedMediaFile> value) {
      debugPrint(
          'Shared when in memory: ${value.map((f) => f.path).join(',')}');
      setState(() {
        _sharedFiles = value;
      });
    }, onError: (err) {
      debugPrint('getIntentDataStream error: $err');
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      debugPrint('Shared when closed: ${value.map((f) => f.path).join(',')}');
      setState(() {
        _sharedFiles = value;
      });
    });

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      setState(() {
        _sharedText = value;
      });
    }, onError: (err) {
      debugPrint('getLinkStream error: $err');
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String? value) {
      debugPrint('Shared text when closed: $value');
      setState(() {
        _sharedText = value;
      });
      return value;
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EncryptionCubit>(
          lazy: false,
          create: (BuildContext context) => EncryptionCubit(),
        ),
        BlocProvider<VectorClockCubit>(
          lazy: false,
          create: (BuildContext context) => VectorClockCubit(),
        ),
        BlocProvider<JournalEntitiesCubit>(
          lazy: false,
          create: (BuildContext context) => JournalEntitiesCubit(),
        ),
        BlocProvider<ImapCubit>(
          lazy: false,
          create: (BuildContext context) => ImapCubit(
            encryptionCubit: BlocProvider.of<EncryptionCubit>(context),
            journalEntitiesCubit:
                BlocProvider.of<JournalEntitiesCubit>(context),
          ),
        ),
        BlocProvider<OutboundQueueCubit>(
          lazy: false,
          create: (BuildContext context) => OutboundQueueCubit(
            encryptionCubit: BlocProvider.of<EncryptionCubit>(context),
            imapCubit: BlocProvider.of<ImapCubit>(context),
          ),
        ),
        BlocProvider<JournalCubit>(
          lazy: false,
          create: (BuildContext context) => JournalCubit(
            outboundQueueCubit: BlocProvider.of<OutboundQueueCubit>(context),
            vectorClockCubit: BlocProvider.of<VectorClockCubit>(context),
            journalEntitiesCubit:
                BlocProvider.of<JournalEntitiesCubit>(context),
          ),
        ),
        BlocProvider<AudioRecorderCubit>(
          create: (BuildContext context) => AudioRecorderCubit(
            outboundQueueCubit: BlocProvider.of<OutboundQueueCubit>(context),
            journalEntitiesCubit:
                BlocProvider.of<JournalEntitiesCubit>(context),
            vectorClockCubit: BlocProvider.of<VectorClockCubit>(context),
          ),
        ),
        BlocProvider<AudioPlayerCubit>(
          create: (BuildContext context) => AudioPlayerCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'WISELY',
        theme: ThemeData(
          primarySwatch: Colors.grey,
        ),
        home: const WiselyHomePage(title: 'WISELY'),
      ),
    );
  }
}

class WiselyHomePage extends StatefulWidget {
  const WiselyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<WiselyHomePage> createState() => _WiselyHomePageState();
}

class _WiselyHomePageState extends State<WiselyHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();

    SecureStorage.writeValue('foo', 'some secret for testing');
  }

  static const List<Widget> _widgetOptions = <Widget>[
    JournalPage(),
    EditorPage(),
    PhotoImportPage(),
    AudioPage(),
    HealthPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            color: AppColors.headerFontColor,
            fontFamily: 'Oswald',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.headerBgColor,
      ),
      backgroundColor: AppColors.bodyBgColor,
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_roll),
            label: 'Photos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: 'Audio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: 'Health',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: AppColors.headerFontColor,
        backgroundColor: AppColors.headerBgColor,
        onTap: _onItemTapped,
      ),
    );
  }
}
