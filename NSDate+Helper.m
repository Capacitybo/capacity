//
// NSDate+Helper.h
//
// Created by Billy Gray on 2/26/09.
// Copyright (c) 2009–2012, ZETETIC LLC
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the ZETETIC LLC nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY ZETETIC LLC ''AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL ZETETIC LLC BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "NSDate+Helper.h"

@implementation NSDate (Helper)

/*
 * This guy can be a little unreliable and produce unexpected results,
 * you're better off using daysAgoAgainstMidnight
 */
- (NSUInteger)daysAgo {
    NSDate *today = [NSDate date];
    NSCalendar *calendar = [today cachedCurrentCalendar];

    NSDateComponents *components = [calendar components:(NSDayCalendarUnit)
											   fromDate:self
												 toDate:today
												options:0];
	return [components day];
}

- (NSUInteger)daysAgoAgainstMidnight {
	// get a midnight version of ourself:
	NSDateFormatter *mdf = [[NSDateFormatter alloc] init];
	[mdf setDateFormat:@"yyyy-MM-dd"];
	NSDate *midnight = [mdf dateFromString:[mdf stringFromDate:self]];
	
	return (int)[midnight timeIntervalSinceNow] / (60*60*24) *-1;
}

- (NSString *)stringDaysAgo {
	return [self stringDaysAgoAgainstMidnight:YES];
}

- (NSString *)stringDaysAgoAgainstMidnight:(BOOL)flag {
	NSUInteger daysAgo = (flag) ? [self daysAgoAgainstMidnight] : [self daysAgo];
	NSString *text = nil;
	switch (daysAgo) {
		case 0:
			text = @"Today";
			break;
		case 1:
			text = @"Yesterday";
			break;
		default:
			text = [NSString stringWithFormat:@"%lu days ago", (unsigned long)daysAgo];
	}
	return text;
}

- (NSUInteger)weekday {
    NSCalendar *calendar = [self cachedCurrentCalendar];
    NSDateComponents *weekdayComponents = [calendar components:(NSWeekdayCalendarUnit) fromDate:self];
	return [weekdayComponents weekday];
}

- (NSInteger) daysUntilDate:(NSDate *) fromDate {
    return [self differenceUntilDate:fromDate inTimeUnits:NSDayCalendarUnit];
}
- (NSInteger) weeksUntilDate:(NSDate *) fromDate {
    return [self differenceUntilDate:fromDate inTimeUnits:NSWeekCalendarUnit];
}
- (NSInteger) monthsUntilDate:(NSDate*) fromDate {
    return [self differenceUntilDate:fromDate inTimeUnits:NSMonthCalendarUnit];
}

- (NSInteger) differenceUntilDate:(NSDate *) fromDate inTimeUnits:(NSCalendarUnit) calendarUnit {
    NSCalendar *calendar = [self cachedCurrentCalendar];
    
    NSDateComponents * components = [calendar components:calendarUnit fromDate:self toDate:fromDate options:0];

    if (calendarUnit == NSDayCalendarUnit) {
        return components.day;
    } else if (calendarUnit == NSWeekCalendarUnit) {
        return components.week;
    } else if (calendarUnit == NSMonthCalendarUnit) {
        return components.month;
    }
    return 0;
}


+ (NSDate *)dateFromString:(NSString *)string {
	return [NSDate dateFromString:string withFormat:[NSDate dbFormatString]];
}

+ (NSDate *)dateFromString:(NSString *)string withFormat:(NSString *)format {
	NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
	[inputFormatter setDateFormat:format];
	NSDate *date = [inputFormatter dateFromString:string];
	return date;
}

+ (NSString *)stringFromDate:(NSDate *)date withFormat:(NSString *)format {
	return [date stringWithFormat:format];
}

+ (NSString *)stringFromDate:(NSDate *)date {
	return [date string];
}

+ (NSString *)stringForDisplayFromDate:(NSDate *)date prefixed:(BOOL)prefixed {
	/* 
	 * if the date is in today, display 12-hour time with meridian,
	 * if it is within the last 7 days, display weekday name (Friday)
	 * if within the calendar year, display as Jan 23
	 * else display as Nov 11, 2008
	 */
    NSCalendar *calendar = [date cachedCurrentCalendar];
    NSDateFormatter *displayFormatter = [[NSDateFormatter alloc] init];
    
	NSDate *today = [NSDate date];
    NSDateComponents *offsetComponents = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) 
													 fromDate:today];
	
	NSDate *midnight = [calendar dateFromComponents:offsetComponents];
	NSString *displayString = nil;
	
	// comparing against midnight
    NSComparisonResult midnight_result = [date compare:midnight];
	if (midnight_result == NSOrderedDescending) {
		if (prefixed) {
			[displayFormatter setDateFormat:@"'at' h:mm a"]; // at 11:30 am
		} else {
			[displayFormatter setDateFormat:@"h:mm a"]; // 11:30 am
		}
	} else {
		// check if date is within last 7 days
		NSDateComponents *componentsToSubtract = [[NSDateComponents alloc] init];
		[componentsToSubtract setDay:-7];
		NSDate *lastweek = [calendar dateByAddingComponents:componentsToSubtract toDate:today options:0];
        NSComparisonResult lastweek_result = [date compare:lastweek];
		if (lastweek_result == NSOrderedDescending) {
			[displayFormatter setDateFormat:@"EEEE"]; // Tuesday
		} else {
			// check if same calendar year
			NSInteger thisYear = [offsetComponents year];
			
			NSDateComponents *dateComponents = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) 
														   fromDate:date];
			NSInteger thatYear = [dateComponents year];			
			if (thatYear >= thisYear) {
				[displayFormatter setDateFormat:@"MMM d"];
			} else {
				[displayFormatter setDateFormat:@"MMM d, yyyy"];
			}
		}
		if (prefixed) {
			NSString *dateFormat = [displayFormatter dateFormat];
			NSString *prefix = @"'on' ";
			[displayFormatter setDateFormat:[prefix stringByAppendingString:dateFormat]];
		}
	}
	
	// use display formatter to return formatted date string
	displayString = [displayFormatter stringFromDate:date];
    
	return displayString;
}

+ (NSString *)stringForDisplayFromDate:(NSDate *)date {
	return [self stringForDisplayFromDate:date prefixed:NO];
}

- (NSString *)stringWithFormat:(NSString *)format {
	NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
	[outputFormatter setDateFormat:format];
	NSString *timestamp_str = [outputFormatter stringFromDate:self];
	return timestamp_str;
}

- (NSString *)string {
	return [self stringWithFormat:[NSDate dbFormatString]];
}

- (NSString *)stringWithDateStyle:(NSDateFormatterStyle)dateStyle timeStyle:(NSDateFormatterStyle)timeStyle {
	NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
	[outputFormatter setDateStyle:dateStyle];
	[outputFormatter setTimeStyle:timeStyle];
	NSString *outputString = [outputFormatter stringFromDate:self];
	return outputString;
}

- (NSDate *)beginningOfWeek {
	// largely borrowed from "Date and Time Programming Guide for Cocoa"
	// we'll use the default calendar and hope for the best
	NSCalendar *calendar = [self cachedCurrentCalendar];
    NSDate *beginningOfWeek = nil;
	BOOL ok = [calendar rangeOfUnit:NSWeekCalendarUnit startDate:&beginningOfWeek
						   interval:NULL forDate:self];
	if (ok) {
		return beginningOfWeek;
	} 
	
	// couldn't calc via range, so try to grab Sunday, assuming gregorian style
	// Get the weekday component of the current date
	NSDateComponents *weekdayComponents = [calendar components:NSWeekdayCalendarUnit fromDate:self];
	
	/*
	 Create a date components to represent the number of days to subtract from the current date.
	 The weekday value for Sunday in the Gregorian calendar is 1, so subtract 1 from the number of days to subtract from the date in question.  (If today's Sunday, subtract 0 days.)
	 */
	NSDateComponents *componentsToSubtract = [[NSDateComponents alloc] init];
	[componentsToSubtract setDay: 0 - ([weekdayComponents weekday] - 1)];
	beginningOfWeek = nil;
	beginningOfWeek = [calendar dateByAddingComponents:componentsToSubtract toDate:self options:0];
	
	//normalize to midnight, extract the year, month, and day components and create a new date from those components.
	NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
											   fromDate:beginningOfWeek];
	return [calendar dateFromComponents:components];
}

- (NSDate *)beginningOfWeekWithFirstWeekday:(NSUInteger) firstDayNumber {
	// largely borrowed from "Date and Time Programming Guide for Cocoa"
	// we'll use the default calendar and hope for the best
	NSCalendar *calendar = [self cachedCurrentCalendar];
    calendar.firstWeekday = firstDayNumber;
    NSDate *beginningOfWeek = nil;
	BOOL ok = [calendar rangeOfUnit:NSWeekCalendarUnit startDate:&beginningOfWeek
						   interval:NULL forDate:self];
	if (ok) {
		return beginningOfWeek;
	} 
	
	// couldn't calc via range, so try to grab Sunday, assuming gregorian style
	// Get the weekday component of the current date
	NSDateComponents *weekdayComponents = [calendar components:NSWeekdayCalendarUnit fromDate:self];
	
	/*
	 Create a date components to represent the number of days to subtract from the current date.
	 The weekday value for Sunday in the Gregorian calendar is 1, so subtract 1 from the number of days to subtract from the date in question.  (If today's Sunday, subtract 0 days.)
	 */
	NSDateComponents *componentsToSubtract = [[NSDateComponents alloc] init];
	[componentsToSubtract setDay: 0 - ([weekdayComponents weekday] - firstDayNumber)];
	beginningOfWeek = nil;
	beginningOfWeek = [calendar dateByAddingComponents:componentsToSubtract toDate:self options:0];
	
	//normalize to midnight, extract the year, month, and day components and create a new date from those components.
	NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
											   fromDate:beginningOfWeek];
	return [calendar dateFromComponents:components];
}


- (NSDate *)beginningOfDay {
    NSCalendar *calendar = [self cachedCurrentCalendar];
    // Get the weekday component of the current date
	NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) 
											   fromDate:self];
	return [calendar dateFromComponents:components];
}

- (NSDate *)endOfWeek {
    NSCalendar *calendar = [self cachedCurrentCalendar];
    // Get the weekday component of the current date
	NSDateComponents *weekdayComponents = [calendar components:NSWeekdayCalendarUnit fromDate:self];
	NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
	// to get the end of week for a particular date, add (7 - weekday) days
	[componentsToAdd setDay:(7 - [weekdayComponents weekday])];
	NSDate *endOfWeek = [calendar dateByAddingComponents:componentsToAdd toDate:self options:0];
	
	return [endOfWeek dateWithTimeSetToHours:23 minutes:59 seconds:59];
}

- (NSDate *)endOfWeekWithFirstWeekday:(NSUInteger) firstDayNumber {
    NSCalendar *calendar = [self cachedCurrentCalendar];
    // Get the weekday component of the current date
    calendar.firstWeekday = firstDayNumber;
	NSDateComponents *weekdayComponents = [calendar components:NSWeekdayCalendarUnit fromDate:self];
	NSDateComponents *componentsToAdd = [[NSDateComponents alloc] init];
	// to get the end of week for a particular date, add (7 - weekday) days
    [componentsToAdd setDay:((6 + firstDayNumber - [weekdayComponents weekday]) % 7)];
	
    //[componentsToAdd setDay:weekdayComponents
    NSDate *endOfWeek = [calendar dateByAddingComponents:componentsToAdd toDate:self options:0];
	
	return [endOfWeek dateWithTimeSetToHours:23 minutes:59 seconds:59];
}

-(NSDate *) dateWithZeroTime 
{

    NSCalendar *calendar = [self cachedCurrentCalendar];
    
    NSDateComponents *dateComponents = [calendar components:( NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit ) fromDate:self];
    
    NSDate *dateWithNoTime = [calendar dateFromComponents:dateComponents];
    
    return dateWithNoTime;
    
}

- (NSDate *)dateByAddingDays:(int) numberOfDaysToAdd {
    NSDateComponents *comps = [[self cachedCurrentCalendar] components:
                               NSYearCalendarUnit |
                               NSMonthCalendarUnit |
                               NSDayCalendarUnit |
                               NSHourCalendarUnit |
                               NSMinuteCalendarUnit |
                               NSSecondCalendarUnit
                                                              fromDate:self];
    comps.day += numberOfDaysToAdd;
    return [[self cachedCurrentCalendar] dateFromComponents:comps];
}

- (NSCalendar *)cachedCurrentCalendar
{
    static NSCalendar *result;
    if (!result)
    {
        result = [NSCalendar currentCalendar];
    }
    return result;
}

- (NSDate *) dateWithTimeSetToHours:(int) hr minutes:(int) min seconds:(int) sec 
{
    NSCalendar *calendar = [self cachedCurrentCalendar];
    
    NSDateComponents *dateComponents = [calendar components:( NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit ) fromDate:self];
    
    [dateComponents setHour:hr];
    [dateComponents setMinute:min];
    [dateComponents setSecond:sec];
    NSDate *newDate = [calendar dateFromComponents:dateComponents];
    
    return newDate;
}


+ (NSString *)dateFormatString {
	return @"yyyy-MM-dd";
}

+ (NSString *)timeFormatString {
	return @"HH:mm:ss";
}

+ (NSString *)timestampFormatString {
	return @"yyyy-MM-dd HH:mm:ss";
}

// preserving for compatibility
+ (NSString *)dbFormatString {	
	return [NSDate timestampFormatString];
}

+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [fromDateTime cachedCurrentCalendar];
    
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate
                 interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate
                 interval:NULL forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSDayCalendarUnit
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}

@end
