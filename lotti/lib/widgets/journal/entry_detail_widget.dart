import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:lotti/blocs/journal/persistence_cubit.dart';
import 'package:lotti/classes/entry_text.dart';
import 'package:lotti/classes/journal_entities.dart';
import 'package:lotti/theme.dart';
import 'package:lotti/utils/image_utils.dart';
import 'package:lotti/widgets/audio/audio_player.dart';
import 'package:lotti/widgets/journal/editor_tools.dart';
import 'package:lotti/widgets/journal/editor_widget.dart';
import 'package:lotti/widgets/journal/entry_tools.dart';
import 'package:lotti/widgets/misc/map_widget.dart';
import 'package:lotti/widgets/misc/survey_summary.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/src/provider.dart';

class EntryDetailWidget extends StatefulWidget {
  final JournalEntity item;
  const EntryDetailWidget({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  State<EntryDetailWidget> createState() => _EntryDetailWidgetState();
}

class _EntryDetailWidgetState extends State<EntryDetailWidget> {
  Directory? docDir;

  @override
  void initState() {
    super.initState();

    getApplicationDocumentsDirectory().then((value) {
      setState(() {
        docDir = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.entryBgColor,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ListView(
        shrinkWrap: false,
        children: <Widget>[
          widget.item.maybeMap(
            journalAudio: (JournalAudio audio) {
              QuillController _controller =
                  makeController(serializedQuill: audio.entryText?.quill);

              void saveText() {
                EntryText entryText = entryTextFromController(_controller);

                context
                    .read<PersistenceCubit>()
                    .updateJournalEntity(widget.item, entryText);
              }

              return Column(
                children: [
                  EditorWidget(
                    controller: _controller,
                    height: 240,
                    saveFn: saveText,
                  ),
                  const AudioPlayerWidget(),
                ],
              );
            },
            journalImage: (JournalImage image) {
              QuillController _controller =
                  makeController(serializedQuill: image.entryText?.quill);

              void saveText() {
                EntryText entryText = entryTextFromController(_controller);

                context
                    .read<PersistenceCubit>()
                    .updateJournalEntity(widget.item, entryText);
              }

              return Column(
                children: [
                  EntryImageWidget(
                    journalImage: image,
                    height: 400,
                  ),
                  EditorWidget(
                    controller: _controller,
                    //height: 240,
                    saveFn: saveText,
                  ),
                ],
              );
            },
            journalEntry: (JournalEntry journalEntry) {
              QuillController _controller =
                  makeController(serializedQuill: journalEntry.entryText.quill);

              void saveText() {
                context.read<PersistenceCubit>().updateJournalEntity(
                    widget.item, entryTextFromController(_controller));
              }

              return EditorWidget(
                controller: _controller,
                //height: 240,
                saveFn: saveText,
              );
            },
            measurement: (MeasurementEntry entry) {
              QuillController _controller =
                  makeController(serializedQuill: entry.entryText?.quill);

              void saveText() {
                context.read<PersistenceCubit>().updateJournalEntity(
                    widget.item, entryTextFromController(_controller));
              }

              return EditorWidget(
                controller: _controller,
                //height: 240,
                saveFn: saveText,
              );
            },
            survey: (SurveyEntry surveyEntry) =>
                SurveySummaryWidget(surveyEntry),
            quantitative: (qe) => qe.data.map(
              cumulativeQuantityData: (qd) => Padding(
                padding: const EdgeInsets.all(24.0),
                child: InfoText(
                  'End: ${df.format(qe.meta.dateTo)}'
                  '\n${formatType(qd.dataType)}: '
                  '${nf.format(qd.value)} ${formatUnit(qd.unit)}',
                ),
              ),
              discreteQuantityData: (qd) => Padding(
                padding: const EdgeInsets.all(24.0),
                child: InfoText(
                  'End: ${df.format(qe.meta.dateTo)}'
                  '\n${formatType(qd.dataType)}: '
                  '${nf.format(qd.value)} ${formatUnit(qd.unit)}',
                ),
              ),
            ),
            orElse: () => Container(),
          ),
          widget.item.maybeMap(
            journalAudio: (audio) => MapWidget(
              geolocation: audio.geolocation,
            ),
            journalImage: (image) => MapWidget(
              geolocation: image.geolocation,
            ),
            journalEntry: (entry) => MapWidget(
              geolocation: entry.geolocation,
            ),
            measurement: (entry) => MapWidget(
              geolocation: entry.geolocation,
            ),
            orElse: () => Container(),
          ),
        ],
      ),
    );
  }
}

class EntryImageWidget extends StatefulWidget {
  final JournalImage journalImage;
  final int height;
  final BoxFit fit;

  const EntryImageWidget(
      {Key? key,
      required this.journalImage,
      required this.height,
      this.fit = BoxFit.scaleDown})
      : super(key: key);

  @override
  State<EntryImageWidget> createState() => _EntryImageWidgetState();
}

class _EntryImageWidgetState extends State<EntryImageWidget> {
  Directory? docDir;

  @override
  void initState() {
    super.initState();

    getApplicationDocumentsDirectory().then((value) {
      setState(() {
        docDir = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (docDir != null) {
      File file =
          File(getFullImagePathWithDocDir(widget.journalImage, docDir!));

      return Container(
        color: Colors.black,
        height: widget.height.toDouble(),
        child: Image.file(
          file,
          cacheHeight: widget.height * 3,
          width: double.infinity,
          height: widget.height.toDouble(),
          fit: widget.fit,
        ),
      );
    } else {
      return Container();
    }
  }
}
