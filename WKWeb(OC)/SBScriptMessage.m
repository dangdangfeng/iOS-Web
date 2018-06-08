
#import "SBScriptMessage.h"

@implementation SBScriptMessage

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@:{method:%@,params:%@,callback:%@}>", NSStringFromClass([self class]),self.method, self.params, self.callback];
}

@end
