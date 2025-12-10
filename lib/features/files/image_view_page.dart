import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/files_repository.dart';
import '../../data/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../auth/auth_cubit.dart';
import 'files_cubit.dart';

class ImageViewPage extends StatelessWidget {
  final String imageId;
  const ImageViewPage({super.key, required this.imageId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<FilesRepository>();
    final e = repo.getById(imageId) as ImageItem;
    final isFile = e.imagePathOrUrl.startsWith('/');

    return Scaffold(
      appBar: AppBar(title: Text(e.title)),
      body: Center(
        child: isFile
            ? Image.file(File(e.imagePathOrUrl), fit: BoxFit.contain)
            : CachedNetworkImage(
          imageUrl: e.imagePathOrUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => const CircularProgressIndicator(),
          errorWidget: (context, url, error) => const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              Text('Image not available offline'),
            ],
          ),
        ),
      ),
    );
  }
}
