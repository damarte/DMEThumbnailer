DMEThumbnailer
=============

DMEThumbnailer is a thumbnail generator for images, MP4 videos and PDF Documents.

##Instalation

CocoaPods, by podfile

```
platform :ios, '6.0'
pod "DMEThumbnailer"
```

or copy the contents of `/DMEThumbnailer` into your project.

##Demo App

Navigate to `/DMEThumbnailerExample` and open the proyect file.

##How do I use DMEThumnailer

Import `DMEThumbnailer.h`

DMEThumbnailer required AVFoundation Framework, include it in your proyect and import it.

```
#import <AVFoundation/AVFoundation.h>
```

DMEThumbnailer is a singleton class. To create two types of thumbnails "small" (120px x 80px) and "large" (240px x 160px) you can do:

```
NSDictionary *sizes = @{
  @"small": [NSValue valueWithCGSize:(CGSize){120, 80}],
  @"large": [NSValue valueWithCGSize:(CGSize){240, 160}]
};
[DMEThumbnailer sharedInstance].sizes = sizes;
```

This generates thumbnails stored in the cache directory in the Thumbs subfolder.

##Generating thumbnails

You can generate all the thumbnails defined in the last step with these methods:

```
// Generate thumbnails from an image:
-(void)generateImageThumbnails:(NSString *)aPath afterGenerate:(GenerateThumbCompletionBlock)afterBlock completionBlock:(GenerateThumbsCompletionBlock)block

// Generate thumbnails from a video:
-(void)generateVideoThumbnails:(NSString *)aPath afterGenerate:(GenerateThumbCompletionBlock)afterBlock completionBlock:(GenerateThumbsCompletionBlock)block

// Generate thumbnails from a pdf
-(void)generatePDFThumbnails:(NSString *)aPath afterGenerate:(GenerateThumbCompletionBlock)afterBlock completionBlock:(GenerateThumbsCompletionBlock)block
```

The block afterGenerate will execute when individual thumbnails generate but before save then.

Three methods completion block return a NSDictionary with UIImages.

##Showing specified thumbnail

You can take a specified type of thumbnail for file with these method:

```
-(UIImage *)readThumb:(NSString *)aPath withPrefix:(NSString *)aPrefix
```

Prefix is the key of thumbnail in dictionary that we created an assigned tu sizes property of DMEThumbnailer. Example:

```
UIImage *smallThumb = [[DMEThumbnailer sharedInstance] readThumb:@"path/to/file" withPrefix:@"small"]
```

##Individual thumbnails

You can also create individual thumbnail for file with these methods:

```
-(void)generateImageThumbnail:(NSString *)aPath widthSize:(CGSize)aSize completionBlock:(GenerateThumbCompletionBlock)block

-(void)generateVideoThumbnail:(NSString *)aPath widthSize:(CGSize)aSize completionBlock:(GenerateThumbCompletionBlock)block

-(void)generatePDFThumbnail:(NSString *)aPath widthSize:(CGSize)aSize completionBlock:(GenerateThumbCompletionBlock)block
```

Three methods completion block return a UIImage pointer for you can modify it before save.

Then to recover an individual thumbnail:

```
-(UIImage *)readThumb:(NSString *)aPath
```

##Removing thumbnails


```
-(void)removeThumbnails:(NSString *)aPath
-(BOOL)removeThumb:(NSString *)aPath;
```
