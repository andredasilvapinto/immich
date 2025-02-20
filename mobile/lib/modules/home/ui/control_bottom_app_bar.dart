import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/modules/album/providers/album.provider.dart';
import 'package:immich_mobile/modules/album/providers/shared_album.provider.dart';
import 'package:immich_mobile/modules/album/ui/add_to_album_sliverlist.dart';
import 'package:immich_mobile/modules/home/models/selection_state.dart';
import 'package:immich_mobile/modules/home/ui/delete_dialog.dart';
import 'package:immich_mobile/modules/home/ui/upload_dialog.dart';
import 'package:immich_mobile/shared/providers/server_info.provider.dart';
import 'package:immich_mobile/shared/ui/drag_sheet.dart';
import 'package:immich_mobile/shared/models/album.dart';

class ControlBottomAppBar extends ConsumerWidget {
  final void Function(bool shareLocal) onShare;
  final void Function()? onFavorite;
  final void Function()? onArchive;
  final void Function()? onDelete;
  final Function(Album album) onAddToAlbum;
  final void Function() onCreateNewAlbum;
  final void Function() onUpload;
  final void Function()? onStack;
  final void Function()? onEditTime;
  final void Function()? onEditLocation;
  final void Function()? onRemoveFromAlbum;

  final bool enabled;
  final bool unfavorite;
  final bool unarchive;
  final SelectionAssetState selectionAssetState;

  const ControlBottomAppBar({
    Key? key,
    required this.onShare,
    this.onFavorite,
    this.onArchive,
    this.onDelete,
    required this.onAddToAlbum,
    required this.onCreateNewAlbum,
    required this.onUpload,
    this.onStack,
    this.onEditTime,
    this.onEditLocation,
    this.onRemoveFromAlbum,
    this.selectionAssetState = const SelectionAssetState(),
    this.enabled = true,
    this.unarchive = false,
    this.unfavorite = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var hasRemote =
        selectionAssetState.hasRemote || selectionAssetState.hasMerged;
    var hasLocal = selectionAssetState.hasLocal;
    final trashEnabled =
        ref.watch(serverInfoProvider.select((v) => v.serverFeatures.trash));
    final albums = ref.watch(albumProvider).where((a) => a.isRemote).toList();
    final sharedAlbums = ref.watch(sharedAlbumProvider);

    List<Widget> renderActionButtons() {
      return [
        if (hasRemote)
          ControlBoxButton(
            iconData: Icons.share_rounded,
            label: "control_bottom_app_bar_share".tr(),
            onPressed: enabled ? () => onShare(false) : null,
          ),
        ControlBoxButton(
          iconData: Icons.ios_share_rounded,
          label: "control_bottom_app_bar_share_to".tr(),
          onPressed: enabled ? () => onShare(true) : null,
        ),
        if (hasRemote && onArchive != null)
          ControlBoxButton(
            iconData: unarchive ? Icons.unarchive : Icons.archive,
            label: (unarchive
                    ? "control_bottom_app_bar_unarchive"
                    : "control_bottom_app_bar_archive")
                .tr(),
            onPressed: enabled ? onArchive : null,
          ),
        if (hasRemote && onFavorite != null)
          ControlBoxButton(
            iconData: unfavorite
                ? Icons.favorite_border_rounded
                : Icons.favorite_rounded,
            label: (unfavorite
                    ? "control_bottom_app_bar_unfavorite"
                    : "control_bottom_app_bar_favorite")
                .tr(),
            onPressed: enabled ? onFavorite : null,
          ),
        if (onDelete != null)
          ControlBoxButton(
            iconData: Icons.delete_outline_rounded,
            label: "control_bottom_app_bar_delete".tr(),
            onPressed: enabled
                ? () {
                    if (!trashEnabled) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return DeleteDialog(
                            onDelete: onDelete!,
                          );
                        },
                      );
                    } else {
                      onDelete!();
                    }
                  }
                : null,
          ),
        if (hasRemote && onEditTime != null)
          ControlBoxButton(
            iconData: Icons.edit_calendar_outlined,
            label: "control_bottom_app_bar_edit_time".tr(),
            onPressed: enabled ? onEditTime : null,
          ),
        if (hasRemote && onEditLocation != null)
          ControlBoxButton(
            iconData: Icons.edit_location_alt_outlined,
            label: "control_bottom_app_bar_edit_location".tr(),
            onPressed: enabled ? onEditLocation : null,
          ),
        if (!hasLocal &&
            selectionAssetState.selectedCount > 1 &&
            onStack != null)
          ControlBoxButton(
            iconData: Icons.filter_none_rounded,
            label: "control_bottom_app_bar_stack".tr(),
            onPressed: enabled ? onStack : null,
          ),
        if (onRemoveFromAlbum != null)
          ControlBoxButton(
            iconData: Icons.delete_sweep_rounded,
            label: 'album_viewer_appbar_share_remove'.tr(),
            onPressed: enabled ? onRemoveFromAlbum : null,
          ),
        if (hasLocal)
          ControlBoxButton(
            iconData: Icons.backup_outlined,
            label: "Upload",
            onPressed: enabled
                ? () => showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return UploadDialog(
                          onUpload: onUpload,
                        );
                      },
                    )
                : null,
          ),
      ];
    }

    return DraggableScrollableSheet(
      initialChildSize: hasRemote ? 0.30 : 0.18,
      minChildSize: 0.18,
      maxChildSize: hasRemote ? 0.60 : 0.18,
      snap: true,
      builder: (
        BuildContext context,
        ScrollController scrollController,
      ) {
        return Card(
          color: context.isDarkTheme ? Colors.grey[900] : Colors.grey[100],
          surfaceTintColor: Colors.transparent,
          elevation: 18.0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          margin: const EdgeInsets.all(0),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 12),
                    const CustomDraggingHandle(),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 70,
                      child: ListView(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        children: renderActionButtons(),
                      ),
                    ),
                    if (hasRemote)
                      const Divider(
                        indent: 16,
                        endIndent: 16,
                        thickness: 1,
                      ),
                    if (hasRemote)
                      AddToAlbumTitleRow(
                        onCreateNewAlbum: enabled ? onCreateNewAlbum : null,
                      ),
                  ],
                ),
              ),
              if (hasRemote)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: AddToAlbumSliverList(
                    albums: albums,
                    sharedAlbums: sharedAlbums,
                    onAddToAlbum: onAddToAlbum,
                    enabled: enabled,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class AddToAlbumTitleRow extends StatelessWidget {
  const AddToAlbumTitleRow({
    super.key,
    required this.onCreateNewAlbum,
  });

  final VoidCallback? onCreateNewAlbum;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "common_add_to_album",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ).tr(),
          TextButton.icon(
            onPressed: onCreateNewAlbum,
            icon: Icon(
              Icons.add,
              color: context.primaryColor,
            ),
            label: Text(
              "common_create_new_album",
              style: TextStyle(
                color: context.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ).tr(),
          ),
        ],
      ),
    );
  }
}
