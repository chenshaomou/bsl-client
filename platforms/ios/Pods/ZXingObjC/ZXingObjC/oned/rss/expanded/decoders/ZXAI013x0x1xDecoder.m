/*
 * Copyright 2012 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "ZXAI013x0x1xDecoder.h"
#import "ZXBitArray.h"
#import "ZXErrors.h"
#import "ZXGeneralAppIdDecoder.h"

int const AI013x0x1x_HEADER_SIZE = 7 + 1;
int const AI013x0x1x_WEIGHT_SIZE = 20;
int const AI013x0x1x_DATE_SIZE = 16;

@interface ZXAI013x0x1xDecoder ()

@property (nonatomic, copy) NSString *dateCode;
@property (nonatomic, copy) NSString *firstAIdigits;

- (void)encodeCompressedDate:(NSMutableString *)buf currentPos:(int)currentPos;

@end

@implementation ZXAI013x0x1xDecoder

@synthesize dateCode;
@synthesize firstAIdigits;

- (id)initWithInformation:(ZXBitArray *)anInformation firstAIdigits:(NSString *)aFirstAIdigits dateCode:(NSString *)aDateCode {
  if (self = [super initWithInformation:anInformation]) {
    self.dateCode = aDateCode;
    self.firstAIdigits = aFirstAIdigits;
  }

  return self;
}

- (void)dealloc {
  [dateCode release];
  [firstAIdigits release];

  [super dealloc];
}

- (NSString *)parseInformationWithError:(NSError **)error {
  if (self.information.size != AI013x0x1x_HEADER_SIZE + GTIN_SIZE + AI013x0x1x_WEIGHT_SIZE + AI013x0x1x_DATE_SIZE) {
    if (error) *error = NotFoundErrorInstance();
    return nil;
  }
  NSMutableString *buf = [NSMutableString string];
  [self encodeCompressedGtin:buf currentPos:AI013x0x1x_HEADER_SIZE];
  [self encodeCompressedWeight:buf currentPos:AI013x0x1x_HEADER_SIZE + GTIN_SIZE weightSize:AI013x0x1x_WEIGHT_SIZE];
  [self encodeCompressedDate:buf currentPos:AI013x0x1x_HEADER_SIZE + GTIN_SIZE + AI013x0x1x_WEIGHT_SIZE];
  return buf;
}

- (void)encodeCompressedDate:(NSMutableString *)buf currentPos:(int)currentPos {
  int numericDate = [self.generalDecoder extractNumericValueFromBitArray:currentPos bits:AI013x0x1x_DATE_SIZE];
  if (numericDate == 38400) {
    return;
  }
  [buf appendFormat:@"(%@)", dateCode];
  int day = numericDate % 32;
  numericDate /= 32;
  int month = numericDate % 12 + 1;
  numericDate /= 12;
  int year = numericDate;
  if (year / 10 == 0) {
    [buf appendString:@"0"];
  }
  [buf appendFormat:@"%d", year];
  if (month / 10 == 0) {
    [buf appendString:@"0"];
  }
  [buf appendFormat:@"%d", month];
  if (day / 10 == 0) {
    [buf appendString:@"0"];
  }
  [buf appendFormat:@"%d", day];
}

- (void)addWeightCode:(NSMutableString *)buf weight:(int)weight {
  int lastAI = weight / 100000;
  [buf appendFormat:@"(%@%d)", firstAIdigits, lastAI];
}

- (int)checkWeight:(int)weight {
  return weight % 100000;
}

@end
