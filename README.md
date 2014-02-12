DMEThumnailer
=============

DMEThumnailer is a thumbnail generator for images, MP4 videos and PDF Documents.

##Instalation

Cocoapods, by podfile

```
platform :ios, '6.0'
pod "DMEThumnailer"
```

or copy the contents of /DMEThumnailer into your project.

##How do I use DMEThumnailer

Include the following four files in your project:

```
DMEThumnailer.h
DMEThumnailer.m
```

DMEThumbnailer is a singleton class. For create two types of thumbnails "small" (120px x 80px) and "large" (240px x 160px) you can do the next:

```
NSDictionary *sizes = @{
  @"small": [NSValue valueWithCGSize:(CGSize){120, 80}],
  @"large": [NSValue valueWithCGSize:(CGSize){240, 160}]
};
[DMEThumbnailer sharedInstance].sizes = sizes;
```

Generated thumbnails store in cache directory into Thumbs subfolder.

##Generating thumbnails

You can generate all the thumbnails defined in the last step with these methods:

```
-(void)generateImageThumbnails:(NSString *)aUrl
```
Generate an image thumbnails from file path.

```
-(void)generateVideoThumbnails:(NSString *)aUrl
```
Generate an video thumbnails from file path.

```
-(void)generatePDFThumbnails:(NSString *)aUrl
```
Generate an PDF thumbnails from file path.

##Showing specified thumbnail

You can take a specified type of thumbnail for file with these method:

```
-(UIImage *)readThumb:(NSString *)aName withPrefix:(NSString *)aPrefix
```

Prefix is the key of thumbnail in dictionary that we created an assigned tu sizes property of DMEThumbnailer. Example:

```
UIImage *smallThumb = [[DMEThumbnailer sharedInstance] readThumb:@"path/to/file" withPrefix:@"small"]
```

##Individual thumbnails

You can also create individual thumbnail for file with these methods:

```
-(UIImage *)generateImageThumbnail:(NSString *)aUrl widthSize:(CGSize)aSize;

-(void)generateVideoThumbnail:(NSString *)aUrl widthSize:(CGSize)aSize response:(AVAssetImageGeneratorCompletionHandler)aResponse;

-(UIImage *)generatePDFThumbnail:(NSString *)aUrl widthSize:(CGSize)aSize;
```

To recover an individual thumbnail you can use this method:

```
-(UIImage *)readThumb:(NSString *)aName
```

##Removing thumbnails

You can remove thumbnails with this methods:

```
-(void)removeThumbnails:(NSString *)aUrl;
```

Remove all thumbnails types for a file.

```
-(BOOL)removeThumb:(NSString *)aName;
```

Remove individual thumbnail for a file.
