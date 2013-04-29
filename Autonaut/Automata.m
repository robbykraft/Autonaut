//
//  Automata.m
//  Automatouch
//
//  Created by Robby on 12/31/12.
//  Copyright (c) 2012 Robby Kraft. All rights reserved.
//
//                Computational Region
//    |----------------- width ------------------|
//
//    +-----------+------------------+-----------+
//    |  square   |  VISIBLE REGION  |   square  |
//    |           |                  |           |
//    |   H * H   |     W  *  H      |   H * H   |
//    |           |                  |           |
//    |           |   visibleWidth   |           |
//    +-----------+------------------+-----------+
//   to eclipse any effects due to null edge values

#import "Automata.h"

@interface Automata(){
    NSInteger width;
    NSInteger height;
}
@end

@implementation Automata

-(UIImage*) initwithRule:(int)ruleNumber
           randomInitials:(BOOL)randomStart
                    width:(NSInteger)visibleWidth
                   height:(NSInteger)visibleHeight
              retinaScale:(CGFloat)scale
{
    if(ruleNumber > 255 || ruleNumber < 0)
        return nil; //rule number must be between 0 and 255

    width = visibleWidth + visibleHeight*2;
    height = visibleHeight;
    bool binaryRule[8];
    //Convert Decimal to 8-bit Binary
    int powerer, ruleNumberCopy = ruleNumber;
    for(int i=7;i>=0;i--){
        binaryRule[i] = false;
        powerer = pow(2,i);
        if(ruleNumberCopy >= powerer){
            binaryRule[i] = true;
            ruleNumberCopy -= powerer;
        }
    }

    bool *cells = malloc(sizeof(bool)*width*height);

    // Initial conditions
    for(int i = 0; i < width; i++){
        if(randomStart){
            if(arc4random()%2 == 0) cells[i] = false;
            else cells[i] = true;
        }
        else{
            cells[i] = false;
            if(i == ((NSInteger)((width)/2))) cells[i] = true;
        }
    }
    
    //Elementary Cellular Automata Computation
    for(int j = 1;j < height; j++){
        for(int i = 1;i < width; i++){
            int offset = width*(j-1);
            if(( ( cells[(i-1)+offset] &&  cells[i+offset] &&  cells[(i+1)+offset]) && binaryRule[7]) ||
               ( ( cells[(i-1)+offset] &&  cells[i+offset] && !cells[(i+1)+offset]) && binaryRule[6]) ||
               ( ( cells[(i-1)+offset] && !cells[i+offset] &&  cells[(i+1)+offset]) && binaryRule[5]) ||
               ( ( cells[(i-1)+offset] && !cells[i+offset] && !cells[(i+1)+offset]) && binaryRule[4]) ||
               ( (!cells[(i-1)+offset] &&  cells[i+offset] &&  cells[(i+1)+offset]) && binaryRule[3]) ||
               ( (!cells[(i-1)+offset] &&  cells[i+offset] && !cells[(i+1)+offset]) && binaryRule[2]) ||
               ( (!cells[(i-1)+offset] && !cells[i+offset] &&  cells[(i+1)+offset]) && binaryRule[1]) ||
               ( (!cells[(i-1)+offset] && !cells[i+offset] && !cells[(i+1)+offset]) && binaryRule[0]) )
                cells[i+width*j] = true;
            else cells[i+width*j] = false;
        }
    } 
    return [UIImage imageWithData:[self GIFDataFromArray:cells width:visibleWidth height:visibleHeight] scale:scale];
}

-(NSData*) GIFDataFromArray:(bool*)cells width:(int)visibleWidth height:(int)visibleHeight
{
    unsigned char header[30] =                   /*  width  */ /*  height */ /*GCT*/
    {  '\x47','\x49','\x46','\x38','\x39','\x61','\x0f','\x00','\x0f','\x00','\x80','\x00','\x00',
        /*     color 1    *//*    color 2     */
        '\xff','\xff','\xff','\x00','\x00','\x00',
        /*   left  */ /*   top   */  /*  width  */ /*  height *//*LCT*//*LZW Minimum code size */
        '\x2c','\x00','\x00','\x00','\x00','\x0f','\x00','\x0f','\x00','\x00','\x07'};
    /* 1 Byte to Follow*//*EOI STOP*//*EndOfImage*//*GIFFileTerminator*/
    unsigned char footer[4] = {'\x01','\x81','\x00','\x3b'};
    
    // set image size in header
    float littleEndian, fractionalpart, intpart = 0.0;
    if(visibleWidth > 255){
        littleEndian = visibleWidth/256.0;
        fractionalpart = fmodf(littleEndian, intpart);
        header[6] = header[24] = 1+(int)(255*(littleEndian-((int)(littleEndian))));
        header[7] = header[25] = (int)littleEndian;
    }
    else header[6] = header[24] = visibleWidth;
    if(visibleHeight > 255){
        littleEndian = visibleHeight/256.0;
        fractionalpart = fmodf(littleEndian, intpart);
        header[8] = header[26] = 1+(int)(255*(littleEndian-((int)(littleEndian))));
        header[9] = header[27] = (int)littleEndian;
    }
    else header[8] = header[26] = visibleHeight;
    
    NSMutableData *imageData = [[NSMutableData alloc] initWithBytes:header length:sizeof(unsigned char)*30];
    
    int count = 0;
    unsigned char off= '\x00';
    unsigned char on = '\x01';
    unsigned char line[2] = {96+1,'\x80'};  //96 uncompressed bytes to follow (plus one x80 CLEAR bit)
    
    for (int j=0;j<visibleHeight;j++){
        for(int i=0;i<visibleWidth;i++){
            if(count==0) [imageData appendBytes:&line length:2];
            if(cells[height+i+width*j]) [imageData appendBytes:&off length:1];
            else [imageData appendBytes:&on length:1];
            count++;
            if(count == 96) count = 0;
        }
    }
    [imageData appendBytes:footer length:4];
    return imageData;
}

@end
