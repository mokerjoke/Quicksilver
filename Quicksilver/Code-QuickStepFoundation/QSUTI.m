/*
 * QSUTI.c
 * Quicksilver
 *
 * Created by Alcor on 4/5/05.
 * Copyright 2005 Blacktree. All rights reserved.
 *
 */

#include "QSUTI.h"

NSString *QSUTIOfURL(NSURL *fileURL) {
    LSItemInfoRecord infoRec;
	LSCopyItemInfoForURL((CFURLRef)fileURL, kLSRequestTypeCreator|kLSRequestBasicFlagsOnly, &infoRec);
	return QSUTIWithLSInfoRec([fileURL path], &infoRec);
}

NSString *QSUTIOfFile(NSString *path) {
    LSItemInfoRecord infoRec;
	LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:path], kLSRequestTypeCreator|kLSRequestBasicFlagsOnly, &infoRec);
	return QSUTIWithLSInfoRec(path, &infoRec);
}

NSString *QSUTIWithLSInfoRec(NSString *path, LSItemInfoRecord *infoRec) {
	NSString *extension = [path pathExtension];
	if (![extension length])
		extension = nil;
	BOOL isDirectory;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory])
		return nil;

	if (infoRec->flags & kLSItemInfoIsAliasFile)
		return (NSString *)kUTTypeAliasFile;
	if (infoRec->flags & kLSItemInfoIsVolume)
		return (NSString *)kUTTypeVolume;

	NSString *extensionUTI = [(NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)extension, NULL) autorelease];
	if (extensionUTI && ![extensionUTI hasPrefix:@"dyn"])
		return extensionUTI;

	NSString *hfsType = [(NSString *)UTCreateStringForOSType(infoRec->filetype) autorelease];
	if (![hfsType length] && isDirectory)
		return (NSString *)kUTTypeFolder;

	NSString *hfsUTI = [(NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassOSType, (CFStringRef)hfsType, NULL) autorelease];
	if (![hfsUTI hasPrefix:@"dyn"])
		return hfsUTI;

	if ([[NSFileManager defaultManager] isExecutableFileAtPath:path])
		return @"public.executable";

	return (extensionUTI ? extensionUTI : hfsUTI);
}

NSString *QSUTIForAnyTypeString(NSString *type) {
	NSString *itemUTI = NULL;

	OSType filetype = 0;
	NSString *extension = nil;

	if ([type hasPrefix:@"'"] && [type length] == 6)
		filetype = NSHFSTypeCodeFromFileType(type);
	else
		extension = type;
	itemUTI = QSUTIForExtensionOrType(extension, filetype);
	if ([itemUTI hasPrefix:@"dyn"])
		itemUTI = nil;
	return itemUTI;
}

NSString *QSUTIForExtensionOrType(NSString *extension, OSType filetype) {
	NSString *itemUTI = nil;
//	NSLog(@"type %@ %@", extension, NSFileTypeForHFSTypeCode(filetype));
	if (extension != nil) {
		itemUTI = (NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)extension, NULL);
	} else {
		CFStringRef fileTypeUTI = UTCreateStringForOSType(filetype);
		itemUTI = (NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassOSType, fileTypeUTI, NULL);
		CFRelease(fileTypeUTI);
	}
	return [itemUTI autorelease];
}

/* Deprecated */
NSString *QSUTIForInfoRec(NSString *extension, OSType filetype) {
	return QSUTIForExtensionOrType(extension, filetype);
}

