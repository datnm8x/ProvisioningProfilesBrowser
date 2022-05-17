//
//  GenerateHTMLForProfile.h
//  ProvisioningProfileBrowser
//
//  Created by Nguyen Mau Dat on 17/05/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GenerateHTMLForProfile : NSObject

+ (NSString*)generateHTMLPreviewForProfileURL:(NSURL*) url;

@end

NS_ASSUME_NONNULL_END
