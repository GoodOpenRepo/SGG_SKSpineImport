//
//  SGG_SpineBoneAction.m
//  SGG_SKSpineImport
//
//  Created by Michael Redig on 6/2/14.
//  Copyright (c) 2014 Secret Game Group LLC. All rights reserved.
//

#import "SGG_SpineBoneAction.h"

@interface SGG_SpineBoneAction () {
	
	NSMutableArray* translationInput;
	NSMutableArray* rotationInput;
	NSMutableArray* scaleInput;
	
	
}

@end


@implementation SGG_SpineBoneAction

-(id)init {
	if (self = [super init]) {

	}
	return self;
}

-(void)addTranslationAtTime:(CGFloat)time withPoint:(CGPoint)point andCurveInfo:(id)curve {
	if (!translationInput) {
		translationInput = [[NSMutableArray alloc] init];
	}
	
	if (time > _totalLength) {
		_totalLength = time;
	}
	
	NSNumber* timeObject = [NSNumber numberWithDouble:time];
	NSValue* pointObject = [self valueObjectFromPoint:point];
	NSDictionary* translationKeyframe;
	if (curve) {
		translationKeyframe = [NSDictionary dictionaryWithObjects:@[timeObject, pointObject, curve] forKeys:@[@"time", @"point", @"curve"]];
	} else {
		translationKeyframe = [NSDictionary dictionaryWithObjects:@[timeObject, pointObject] forKeys:@[@"time", @"point"]];
	}
	[translationInput addObject:translationKeyframe];

//	NSLog(@"%@", translationInput);
	
}

-(void)addRotationAtTime:(CGFloat)time withAngle:(CGFloat)angle andCurveInfo:(id)curve {
	if (!rotationInput) {
		rotationInput = [[NSMutableArray alloc] init];
	}
	
	if (time > _totalLength) {
		_totalLength = time;
	}
	
	if (angle < 0) {
		angle = 180 + 180 - fabs(angle);
	}
	
	NSNumber* timeObject = [NSNumber numberWithDouble:time];
	NSNumber* angleObject = [NSNumber numberWithDouble:angle];
	NSDictionary* rotationKeyFrame;
	if (curve) {
		rotationKeyFrame = [NSDictionary dictionaryWithObjects:@[timeObject, angleObject, curve] forKeys:@[@"time", @"point", @"curve"]];
	} else {
		rotationKeyFrame = [NSDictionary dictionaryWithObjects:@[timeObject, angleObject] forKeys:@[@"time", @"point"]];
	}
	[rotationInput addObject:rotationKeyFrame];
	
	NSLog(@"%@", rotationInput);
}

-(void)addScaleAtTime:(CGFloat)time withScale:(CGSize)scale andCurveInfo:(id)curve {
	
}

-(void)calculateTotalAction {
	
	if (_timeFrameDelta == 0) {
		_timeFrameDelta = 1.0f/120.0f;
	}
	NSInteger totalFrames = round(_totalLength / _timeFrameDelta);
	NSLog(@"total time: %f, delta: %f totalFrames = %i", _totalLength, _timeFrameDelta, (int)totalFrames);
	
	NSMutableArray* mutableAnimation = [[NSMutableArray alloc] initWithCapacity:totalFrames];
	
	
//translation keyframes
	for (int i = 0; i < translationInput.count; i++) {
		NSDictionary* startKeyFrameDict = translationInput[i];
		NSDictionary* endKeyFrameDict;
		if (i == translationInput.count - 1) {
			endKeyFrameDict = translationInput[i];
		} else {
			endKeyFrameDict = translationInput[i + 1];
		}
		CGFloat startingTime = [startKeyFrameDict[@"time"] doubleValue];
		CGPoint startingLocation = [self pointFromValueObject:startKeyFrameDict[@"point"]];
		id curveInfo = startKeyFrameDict[@"curve"];
		
		CGFloat endingTime = [endKeyFrameDict[@"time"] doubleValue];
		CGPoint endingLocation = [self pointFromValueObject:endKeyFrameDict[@"point"]];
		
		CGFloat sequenceTime = endingTime - startingTime;
		
		NSInteger keyFramesInSequence;
		if (sequenceTime > 0) {
			CGFloat keyFrames = sequenceTime / _timeFrameDelta ;
			keyFramesInSequence = round(keyFrames);
			NSLog(@"float: %f int: %i", keyFrames, (int)keyFramesInSequence);
		} else {
			NSLog(@"fart");
			keyFramesInSequence = 1;
		}
		
//		NSLog(@"curve: %@", curveInfo);
		
		if (curveInfo) {
			NSString* curveString = (NSString*)curveInfo;
			if ([curveInfo isKindOfClass:[NSString class]] && [curveString isEqualToString:@"stepped"]) {
				//stepped
				for (int f = 0; f < keyFramesInSequence; f++) {
					NSMutableDictionary* frameDict = [[NSMutableDictionary alloc] init];
					[frameDict setObject:[self valueObjectFromPoint:CGPointMake(startingLocation.x, startingLocation.y)] forKey:@"position"];
					[mutableAnimation addObject:frameDict];
				}
			} else {
				//timing curve
				NSArray* curveArray = [NSArray arrayWithArray:curveInfo];
//				NSLog(@"curveArray: %@", curveArray);
				CGPoint curvePointOne, curvePointTwo, curvePointThree, curvePointFour;
				curvePointOne = CGPointZero;
				curvePointTwo = CGPointMake([curveArray[0] doubleValue], [curveArray[1] doubleValue]);
				curvePointThree = CGPointMake([curveArray[2] doubleValue], [curveArray[3] doubleValue]);
				curvePointFour = CGPointMake(1.0f, 1.0f);
				
				
				
				CGFloat totalDeltaX = endingLocation.x - startingLocation.x;
				CGFloat totalDeltaY = endingLocation.y - startingLocation.y;
				
//				NSLog(@"p2: %f %f p3: %f %f tDelX: %f yDelY: %f", curvePointTwo.x, curvePointTwo.y, curvePointThree.x, curvePointThree.y, totalDeltaX, totalDeltaY);
				
				for (int f = 0; f < keyFramesInSequence; f++) {
					NSMutableDictionary* frameDict = [[NSMutableDictionary alloc] init];
					CGFloat timeProgress = ((CGFloat)f / (CGFloat)keyFramesInSequence);
					CGFloat bezierProgress = [self getBezierPercentAtXValue:timeProgress withXValuesFromPoint0:curvePointOne.x point1:curvePointTwo.x point2:curvePointThree.x andPoint3:curvePointFour.x];
					
					
					CGPoint bezValues = [self calculateBezierPoint:bezierProgress andPoint0:curvePointOne andPoint1:curvePointTwo andPoint2:curvePointThree andPoint3:curvePointFour];
//					NSLog(@"prog: %f value: %f", bezierProgress, bezValues.y);
					NSLog(@"p2: %f p3: %f timeProg: %f bezProg: %f value: %f\n\n\n", curvePointTwo.x, curvePointThree.x, timeProgress, bezierProgress, bezValues.y);
					
					[frameDict setObject:[self valueObjectFromPoint:CGPointMake(startingLocation.x + totalDeltaX * bezValues.y, startingLocation.y + totalDeltaY * bezValues.y)] forKey:@"position"];
					[mutableAnimation addObject:frameDict];
				}
			}
		} else {
			//linear
			CGFloat deltaX = (endingLocation.x - startingLocation.x) / (keyFramesInSequence);
			CGFloat deltaY = (endingLocation.y - startingLocation.y) / (keyFramesInSequence);
//			NSLog(@"span %f to %f", startingTime, endingTime);
			for (int f = 0; f < keyFramesInSequence; f++) {
				NSMutableDictionary* frameDict = [[NSMutableDictionary alloc] init];
				[frameDict setObject:[self valueObjectFromPoint:CGPointMake(startingLocation.x + f * deltaX, startingLocation.y + f * deltaY)] forKey:@"position"];
				[mutableAnimation addObject:frameDict];
			}
		}
	}
	
	_animation = [NSArray arrayWithArray:mutableAnimation];

	
//	for (int i = 0; i < mutableAnimation.count; i++) {
//		NSDictionary* dict = mutableAnimation[i];
//		NSLog(@"frame: %i point: %f %f", i, [self pointFromValueObject:dict[@"position"]].x, [self pointFromValueObject:dict[@"position"]].y);
//	}
}

-(NSValue*)valueObjectFromPoint:(CGPoint)point {
#if TARGET_OS_IPHONE
	return [NSValue valueWithCGPoint:point];
#else
	return [NSValue valueWithPoint:point];
#endif
	
}

-(CGPoint)pointFromValueObject:(NSValue*)valueObject {
#if TARGET_OS_IPHONE
	return [valueObject CGPointValue];
#else
	return [valueObject pointValue];
#endif
	
}

-(CGPoint)calculateBezierPoint:(CGFloat)t andPoint0:(CGPoint)p0 andPoint1:(CGPoint)p1 andPoint2:(CGPoint)p2 andPoint3:(CGPoint)p3 {
	
	CGFloat u = 1 - t;
	CGFloat tt = t * t;
	CGFloat uu = u * u;
	CGFloat uuu = uu * u;
	CGFloat ttt = tt * t;
	
	
	CGPoint finalPoint = CGPointMake(p0.x * uuu, p0.y * uuu);
	finalPoint = CGPointMake(finalPoint.x + (3 * uu * t * p1.x), finalPoint.y + (3 * uu * t * p1.y));
	finalPoint = CGPointMake(finalPoint.x + (3 * u * tt * p2.x), finalPoint.y + (3 * u * tt * p2.y));
	finalPoint = CGPointMake(finalPoint.x + (ttt * p3.x), finalPoint.y + (ttt * p3.y));
	
	
	return finalPoint;
}


//following algorithm sourced from this page: http://stackoverflow.com/a/17546429/2985369
//start x bezier algorithm

-(NSArray*)solveQuadraticEquationWithA:(double)a andB:(double)b andC:(double)c {
	
	double discriminant = b * b - 4 * a * c;
	
	if (discriminant < 0) {
		NSLog(@"1");
		return nil;
	} else {
		double possibleA = (-b + sqrt(discriminant) / (2 * a));
		double possibleB = (-b - sqrt(discriminant) / (2 * a));
		NSLog(@"2");
		return @[[NSNumber numberWithDouble:possibleA], [NSNumber numberWithDouble:possibleB]];
	}
}


-(NSArray*)solveCubicEquationWithA:(double)a andB:(double)b andC:(double)c andD:(double)d {
	
	if (!a) {
		return [self solveQuadraticEquationWithA:b andB:c andC:d];
	}
	
	double startB = b;
	double startC = c;
	double startD = d;
	
	b /= a;
	c /= a;
	d /= a;
	
//	double p = (3 * c - b * b) / 3;
	double p = (3 * c - ((startB * startB) / (a * a))) / 3;
//	double q = (2 * b * b * b - 9 * b * c + 27 * d) / 27;
	double q = (2 * ((startB * startB * startB) / (a * a * a)) - ((9 * startB * startC) / (a * a)) + (27 * startD) / a) / 27;
	
	if (p == 0) {
		double endValue = pow(-q, (1/3));
		NSLog(@"3");
		return @[[NSNumber numberWithDouble:endValue]];
	} else if (q == 0) {
		double endValueOne = sqrt(-p);
		double endValueTwo = -sqrt(-p);
		NSLog(@"4");
		return @[[NSNumber numberWithDouble:endValueOne], [NSNumber numberWithDouble:endValueTwo]];

	} else {
//		double discriminant = pow((q / 2), 2) + pow((p / 3), 3);
		double discriminant = ((q * q) / 4) + ((p * p * p) / 27);
		
		if (discriminant == 0) {
			double endValue = pow((q / 2), (1 / 3)) - (b / 3);
			NSLog(@"5");
			return @[[NSNumber numberWithDouble:endValue]];

		} else if (discriminant > 0) {
			double endValue = pow( -(q / 2) + sqrt(discriminant), 1 / 3) - pow((q / 2) + sqrt(discriminant), 1 / 3) - b / 3;
			NSLog(@"6");
			return @[[NSNumber numberWithDouble:endValue]];

		} else {
			double r = sqrt( pow( -(p/3), 3));
			double phi = acos(-(q / (2 * sqrt(pow(-(p/3), 3)))));
			
			double s = 2 * pow(r, 1/3);
			
			double endValueOne = s * cos(phi /3) - b / 3;
			double endValueTwo = s * cos((phi + 2 * M_PI) / 3) - b / 3;
			double endValueThree = s * cos((phi + 4 * M_PI) / 3) - b / 3;
			
			NSLog(@"7");
			return @[[NSNumber numberWithDouble:endValueOne], [NSNumber numberWithDouble:endValueTwo], [NSNumber numberWithDouble:endValueThree]];
		}
	}
	
}


-(double)getBezierPercentAtXValue:(double)x withXValuesFromPoint0:(double)p0x point1:(double)p1x point2:(double)p2x andPoint3:(double)p3x {
	
//	if (x == 0 || x == 1) {
//		return x;
//	}
	
	p0x -= x;
	p1x -= x;
	p2x -= x;
	p3x -= x;
	
	double a = p3x - 3 * p2x + 3 * p1x - p0x;
    double b = 3 * p2x - 6 * p1x + 3 * p0x;
    double c = 3 * p1x - 3 * p0x;
	double d = p0x;
	
	
	NSLog(@"  a: %f b: %f c: %f d: %f", a, b, c, d);
	NSArray* roots = [self solveCubicEquationWithA:a andB:b andC:c andD:d];
	
	NSLog(@"roots: %@", roots);

	double closest;

	for (int i = 0; i < roots.count; i++) {
		double root = [roots[i] doubleValue];
		
		if (root >= 0 && root <= 1) {
//			NSLog(@"root exists");
			return root;
		} else {
			if (fabs(root) < 0.5) {
				closest = 0;
//			} else if (1 - fabs(root) > closest) {
			} else {
				closest = 1;
			}
		}
	}
//	
//	NSLog(@"problems: %@", roots);
//	NSLog(@"closest: %f", closest);

	
	return fabs(closest);
}

//end x bezier algorithm

@end
