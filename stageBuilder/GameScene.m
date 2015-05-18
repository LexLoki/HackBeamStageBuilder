//
//  GameScene.m
//  stageBuilder
//
//  Created by Pietro Ribeiro Pepe on 2/27/15.
//  Copyright (c) 2015 Pietro Ribeiro Pepe. All rights reserved.
//

#import "GameScene.h"

@interface GameScene()

@property (nonatomic) UIButton *plusLineButton;
@property (nonatomic) UIButton *minusLineButton;
@property (nonatomic) UIButton *plusColButton;
@property (nonatomic) UIButton *minusColButton;
@property (nonatomic) UIButton *writeFileButton;
@property (nonatomic) UITextField *writeFileText;
@property (nonatomic) UITextField *divideCannonText;

@end

#define MIRROR_1 20 // '-'
#define MIRROR_2 21 // '/'
#define MIRROR_3 22 // '|'
#define MIRROR_4 23 // '\'
#define WALL_V 30
#define WALL_H 31
#define WALL_BOX 32
#define RECEPTOR_ 40
#define KEY_ 50
#define PORTAL_ 70

#define FILEPATH "/Users/Piupas/Desktop/Fases/"
#define DEFAULTWORKSPACEPATH "/Users/lmenezes/MWAPPTECH/HB_StageBuilder/out/"

//EDITAR AQUI. BOTEM O CAMINHO ONDE VAO CRIAR O ARQUIVO

#define MIRROR "mirror"
#define RECEPTOR "receptor"
#define WALL "barreira"
#define WALLBOX "barreiraBox"
#define KEY "password"
#define SHIELD "ProtectionCube"
#define PORTAL "portal"

@implementation GameScene

NSInteger quantLin, quantCol, quantPortal;
CGFloat sizex, sizey;
NSMutableArray *lines, *nodes, *coordinates, *portalLines;
CGRect gameRect;
SKSpriteNode *selectedNode, *selectedNodeBox, *clicked;
NSMutableDictionary *nodesDict;
NSMutableArray *portalOrigin, *portalDestiny, *portals;
SKShapeNode *line;
NSDictionary *codesDict;
CGPoint firstPoint;
bool drawState;
NSString * filePath;
NSString * workspace;


-(void)didMoveToView:(SKView *)view {
    drawState=false;
    //NSString *appFolderPath = [[NSBundle mainBundle] resourcePath];
    //NSFileManager *fileManager = [NSFileManager defaultManager];
    //NSLog(@"App Directory is: %@", appFolderPath);
    //NSLog(@"Directory Contents:\n%@", [fileManager directoryContentsAtPath: appFolderPath]);
    
    [self prepareDictionary];
    quantLin=9; quantCol=5; quantPortal=0;
    gameRect = CGRectMake(0, 0, 0.8*self.frame.size.width, 0.8*self.frame.size.height);
    lines = [NSMutableArray array];
    nodes = [NSMutableArray array];
    coordinates = [NSMutableArray array];
    nodesDict = [NSMutableDictionary dictionary];
    portalDestiny = [NSMutableArray array];
    portalOrigin = [NSMutableArray array];
    portalLines = [NSMutableArray array];
    portals = [NSMutableArray array];
    
    /* Setup your scene here */
    [self setupUI];
    [self drawGameRectangle];
    [self drawGridWithLines:quantLin Columns:quantCol inRect:gameRect];
}

-(void)prepareDictionary
{
    NSArray *keys = [[NSArray alloc]initWithObjects:@MIRROR, @RECEPTOR, @WALL, @WALLBOX, @KEY, @PORTAL,nil];
    NSArray *codes = [[NSArray alloc]initWithObjects:@MIRROR_1, @RECEPTOR_, @WALL_H, @WALL_BOX, @KEY_, @PORTAL_, nil];
    codesDict = [[NSDictionary alloc] initWithObjects:codes forKeys:keys];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    /* Called when a touch begins */
    [self.view endEditing:YES];
    if(touches.count>1)
        return;
    for (UITouch *touch in touches)
    {
        CGPoint location = [touch locationInNode:self];
        if(CGRectContainsPoint(gameRect, location)){
            [self gridTouchBegan:location];
        }
        else{
            NSLog(@"UITOUCH");
            [self UITouchBegan:location];
        }
        break;
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *touch in touches)
    {
        CGPoint location = [touch locationInNode:self];
        if(selectedNode.name!=NULL){
            selectedNode.position=location;
            selectedNodeBox.position=location;
        }
        else if(drawState){
            [self lineMoved:location];
        }
        break;
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *touch in touches)
    {
        CGPoint location = [touch locationInNode:self];
        if(selectedNode.name!=NULL)
        {
            if(CGRectContainsPoint(gameRect, location))
            {
                //drag to grid
                [self placeElementOnPoint:location];
            }
            else
            {
                [selectedNode removeFromParent];
            }
        }
        else if(clicked!=NULL)
            [self gridTouchEnded:location];
        break;
    }
    selectedNode=NULL;
    clicked=NULL;
    drawState=false;
}


-(void)placeElementOnPoint:(CGPoint)location
{
    NSInteger coordinateX = location.x/sizex, coordinateY = location.y/sizey;
    CGPoint point = CGPointMake(coordinateX*sizex+sizex/2, coordinateY*sizey+sizey/2);
    selectedNode.position=CGPointMake(1000,1000);
    SKSpriteNode *nodeThere = (SKSpriteNode*)[self nodeAtPoint:point];
    if(nodeThere.name!=NULL)
        [self removeNode:nodeThere];
    selectedNode.position=point;
    selectedNode.xScale=sizex/selectedNode.texture.size.width;
    selectedNode.yScale=selectedNode.xScale;
    [nodes addObject:selectedNode];
    [coordinates addObject:[NSValue valueWithCGPoint:CGPointMake(coordinateX, coordinateY) ]];
}

-(void)gridTouchBegan:(CGPoint)location{
    location = CGPointMake(sizex*((int)(location.x/sizex))+sizex/2, sizey*((int)(location.y/sizey))+sizey/2);
    SKSpriteNode *node = (SKSpriteNode*)[self nodeAtPoint:location];
    if(node.name!=NULL){
        clicked=node;
        if([node.name isEqualToString:@PORTAL]){
            [self newLineFrom:location];
        }
    }
}

-(void)searchRemovePath:(CGPoint)location{
    NSValue *locValue = [NSValue valueWithCGPoint:location];
    NSInteger quant=portalOrigin.count, i;
    for(i=0;i<quant;i++){
        if([locValue isEqualToValue:portalOrigin[i]]){
            [self removeLineAtIndex:i];
            return;
        }
        if([locValue isEqualToValue:portalDestiny[i]]){
            [self removeLineAtIndex:i];
            return;
        }
    }
}

-(void)removeLineAtIndex:(NSInteger)index{
    [portalLines[index] removeFromParent];
    [portalDestiny removeObjectAtIndex:index];
    [portalOrigin removeObjectAtIndex:index];
    [portalLines removeObjectAtIndex:index];
    
}

-(void)newLineFrom:(CGPoint)location{
    drawState=true;
    [self searchRemovePath:location];
    
    line = [SKShapeNode node];
    UIBezierPath* path = [[UIBezierPath alloc] init];
    [path moveToPoint:location];
    [path addLineToPoint:location];
    line.path=path.CGPath;
    line.strokeColor=[UIColor blueColor];
    line.lineWidth=2;
    [self addChild:line];
    firstPoint = location;
}

-(void)lineMoved:(CGPoint)location{
    UIBezierPath *path = [[UIBezierPath alloc] init];
    [path moveToPoint:firstPoint];
    [path addLineToPoint:location];
    line.path = path.CGPath;
}

-(void)lineEnded:(CGPoint)location{
    location = CGPointMake(((int)(location.x/sizex))*sizex+sizex/2, ((int)(location.y/sizey))*sizey+sizey/2);
    [self searchRemovePath:location];
    
    [self lineMoved:location];
    [portalLines addObject:line];
    [portalOrigin addObject:[NSValue valueWithCGPoint:firstPoint]];
    [portalDestiny addObject:[NSValue valueWithCGPoint:location]];
}


-(void)gridTouchMoved:(CGPoint)location{
    
}

-(void)gridTouchEnded:(CGPoint)location{
    location = CGPointMake(sizex*((int)(location.x/sizex))+sizex/2, sizey*((int)(location.y/sizey))+sizey/2);
    SKSpriteNode *node = (SKSpriteNode*)[self nodeAtPoint:location];
    if([node isEqual:clicked]){
        [self removeNode:node];
        if(drawState){
            [line removeFromParent];
        }
    }
    else if(drawState){
        if([node.name isEqualToString:@PORTAL]){
            [self lineEnded:location];
        }
        else{
            [line removeFromParent];
        }
    }
}

-(void)removeNode:(SKSpriteNode*)node{
    NSInteger index = [nodes indexOfObject:node];
    [node removeFromParent];
    [coordinates removeObjectAtIndex:index];
    [nodes removeObjectAtIndex:index];
}


-(void)UITouchBegan:(CGPoint)location{
    SKSpriteNode *node = (SKSpriteNode*)[self nodeAtPoint:location];
    if(node.name!=NULL){
        selectedNode = [[nodesDict objectForKey:node.name]copy];
        selectedNode.position=location;
        [self addChild:selectedNode];
    }
}

-(void)plusLine{
    quantLin++;
    [self updateGrid];
}
-(void)minusLine{
    quantLin--;
    [self updateGrid];
}
-(void)plusCol{
    quantCol++;
    [self updateGrid];
}
-(void)minusCol{
    quantCol--;
    [self updateGrid];
}

-(void)drawGameRectangle{
    SKShapeNode* gameDraw = [SKShapeNode node];
    UIBezierPath* gameDrawPath = [[UIBezierPath alloc] init];
    CGRect ret = CGRectMake(0, 0,  0.8*self.frame.size.width, 0.8*self.frame.size.height);
    gameDrawPath = [UIBezierPath bezierPathWithRect:ret];
    gameDraw.path = gameDrawPath.CGPath;
    gameDraw.lineWidth = 1.0;
    gameDraw.strokeColor = [[UIColor alloc] initWithRed:65.0/255 green:105.0/255 blue:225.0/255 alpha:0.5];
    gameDraw.antialiased = NO;
    [self addChild:gameDraw];
}

-(void)updateGrid{
    for(SKShapeNode *line in lines){
        [line removeFromParent];
    }
    [lines removeAllObjects];
    [self drawGridWithLines:quantLin Columns:quantCol inRect:gameRect];
    [self repositionNodes];
}

-(void)repositionNodes{
    NSInteger quant=nodes.count, i;
    NSLog(@"%ld",quant);
    for(i=0;i<quant;i++){
        CGPoint coordinate = [coordinates[i] CGPointValue];
        if(coordinate.x>quantCol-1 || coordinate.y>quantLin-1){
            [nodes[i] removeFromParent];
            [nodes removeObjectAtIndex:i];
            [coordinates removeObjectAtIndex:i];
            quant--; i--;
        }
        else{
            SKSpriteNode *node = nodes[i];
            node.position=CGPointMake(coordinate.x*sizex+sizex/2,coordinate.y*sizey+sizey/2);
            node.xScale=sizex/node.texture.size.width;
            node.yScale=node.xScale;
        }
    }
}

-(void)drawGridWithLines:(NSInteger)quantLin Columns:(NSInteger)quantCol inRect:(CGRect)bounds{
    NSInteger i;
    //sizey = self.frame.size.height/quantLin;
    //sizex = self.frame.size.width/quantCol;
    sizey = bounds.size.height/quantLin;
    sizex = bounds.size.width/quantCol;
    if(sizex>sizey)
        sizex=sizey;
    else
        sizey=sizex;
    
    for(i=0;i<quantLin+1;i++)
        [self drawLineFrom:CGPointMake(0, i*sizey) to:CGPointMake(quantCol*sizex, i*sizey)];
    for(i=0;i<quantCol+1;i++)
        [self drawLineFrom:CGPointMake(i*sizex, 0) to:CGPointMake(i*sizex, quantLin*sizex)];
    //gridLin = (int) quantLin;
    //gridCol = (int) quantCol;
}

-(void)drawLineFrom:(CGPoint)initial to:(CGPoint)final{
    SKShapeNode *yourline = [SKShapeNode node];
    CGMutablePathRef pathToDraw = CGPathCreateMutable();
    CGPathMoveToPoint(pathToDraw, NULL, initial.x, initial.y);
    CGPathAddLineToPoint(pathToDraw, NULL, final.x, final.y);
    yourline.path = pathToDraw;
    [yourline setStrokeColor:[UIColor redColor]];
    [self addChild:yourline];
    [lines addObject:yourline];
}

-(void)writeToTxt{
    NSString *filename = self.writeFileText.text;
    workspace=@DEFAULTWORKSPACEPATH ;
    //workspace=@FILEPATH;
    if(filename.length==0)
        filename= [NSString stringWithFormat:@"levelR%d",arc4random_uniform(3000)];
    NSString *path = [NSString stringWithFormat:@"%@%@.txt",workspace, filename];
    FILE *arq;
    arq=fopen([path UTF8String],"wt");
    if(arq==NULL)
    {
        NSLog(@"Error path: %@ does not exist. Please especify one that exists",path);
        UIAlertController* notFoundAlert;
        notFoundAlert= [[UIAlertController alloc] init];
        notFoundAlert =
        [UIAlertController
         alertControllerWithTitle:@"Warning"
         message: [NSString stringWithFormat:@"Error path: %@ does not exist. Please especify one that exists",path]
         preferredStyle:[[UIDevice currentDevice].model containsString:@"iPad"]?UIAlertControllerStyleAlert:UIAlertControllerStyleActionSheet];
        //If iPad StyleAlert else (iPhone) StyleActionSheet
        UIAlertAction* okButton = [UIAlertAction
                                    actionWithTitle:@"ok"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action)
                                    {
                                        [notFoundAlert dismissViewControllerAnimated:YES completion:nil];
                                        
                                    }];
       
        [notFoundAlert addAction:okButton];
        [self.view.window.rootViewController presentViewController:notFoundAlert animated:YES completion:nil];
        return;
        
    }
    
    CGPoint initial = CGPointMake(sizex/2, sizey*quantLin-sizey/2);
    NSInteger i,j;
    int code;
    for(i=0;i<quantLin;i++){
        for(j=0;j<quantCol;j++){
            code=[self getCodeOfObjectIn:CGPointMake(initial.x+j*sizex, initial.y-i*sizey)];
            NSLog(@"code for %ld x %ld = %d", j, i, code);
            fprintf(arq,"%d\t", code);
        }
        fprintf(arq,"\n");
    }
    
    //first area delimitation
    fprintf(arq,"\n1 1 1 1"); //at first all 1
    
    //then portal information
    NSInteger quant=portalOrigin.count;
    if(quant)
        fprintf(arq,"\n\n");
    for(i=0;i<quant;i++){
        NSInteger A = [portals indexOfObject:[self nodeAtPoint:[portalOrigin[i] CGPointValue]]];
        NSInteger B = [portals indexOfObject:[self nodeAtPoint:[portalDestiny[i] CGPointValue]]];
        fprintf(arq, "%ld %ld ", (long)A, (long)B);
    }
    [portals removeAllObjects];
    
    //then divide cannon
    fprintf(arq,"\n\n%s", [self.divideCannonText.text UTF8String]);
    fclose(arq);
}

-(int)getCodeOfObjectIn:(CGPoint)location{
    int code;
    SKSpriteNode *node = (SKSpriteNode*)[self nodeAtPoint:location];
    if(node.name==NULL)
        return 0;
    code = [[codesDict objectForKey:node.name] intValue];
    if(code==MIRROR_1){
        code += (int)(node.zRotation/(M_PI/4));
    }
    else if(code==WALL_H){
        if(((int)(node.zRotation/(M_PI/4)+0.5))==2)
            code=WALL_V;
    }
    else if(code==PORTAL_){
        [self sortPortal:node];
        quantPortal++;
    }
    return code;
}

-(void)sortPortal:(SKSpriteNode*)portal{
    NSInteger i, quant=portals.count;
    for(i=0;i<quant;i++){
        SKSpriteNode *node = portals[i];
        if(portal.position.y>node.position.y || (portal.position.y==node.position.y && portal.position.x<node.position.x))
            break;
    }
    [portals insertObject:portal atIndex:i];
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

-(void)setupUI{
    self.minusLineButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 0.1*self.frame.size.width, 0.1*self.frame.size.height)];
    [self.minusLineButton setBackgroundImage:[UIImage imageNamed:@"leftArrow"] forState:UIControlStateNormal];
    [self.minusLineButton addTarget:self action:@selector(minusLine) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.minusLineButton];
    
    self.plusLineButton = [[UIButton alloc]initWithFrame:CGRectMake(0.1*self.frame.size.width, 0, 0.1*self.frame.size.width, 0.1*self.frame.size.height)];
    [self.plusLineButton setBackgroundImage:[UIImage imageNamed:@"rightArrow"] forState:UIControlStateNormal];
    [self.plusLineButton addTarget:self action:@selector(plusLine) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.plusLineButton];
    
    self.minusColButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0.1*self.frame.size.height, 0.1*self.frame.size.width, 0.1*self.frame.size.height)];
    [self.minusColButton setBackgroundImage:[UIImage imageNamed:@"leftArrow"] forState:UIControlStateNormal];
    [self.minusColButton addTarget:self action:@selector(minusCol) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.minusColButton];
    
    self.plusColButton = [[UIButton alloc]initWithFrame:CGRectMake(0.1*self.frame.size.width, 0.1*self.frame.size.height, 0.1*self.frame.size.width, 0.1*self.frame.size.height)];
    [self.plusColButton setBackgroundImage:[UIImage imageNamed:@"rightArrow"] forState:UIControlStateNormal];
    [self.plusColButton addTarget:self action:@selector(plusCol) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.plusColButton];
    
    self.writeFileButton = [[UIButton alloc]initWithFrame:CGRectMake(0.2*self.frame.size.width, 0.1*self.frame.size.height, 0.1*self.frame.size.width, 0.1*self.frame.size.height)];
    [self.writeFileButton setBackgroundImage:[UIImage imageNamed:@"rightArrow"] forState:UIControlStateNormal];
    [self.writeFileButton addTarget:self action:@selector(writeToTxt) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.writeFileButton];
    
    self.writeFileText = [[UITextField alloc] initWithFrame:CGRectMake(0.35*self.frame.size.width, 0.12*self.frame.size.height, 0.4*self.frame.size.width, 0.06*self.frame.size.height)];
    [self.writeFileText setBackground:[UIImage imageNamed:@"textbox"]];
    self.writeFileText.delegate = self;
    self.writeFileText.textAlignment=NSTextAlignmentCenter;
    [self.view addSubview:self.writeFileText];
    
    self.divideCannonText = [[UITextField alloc] initWithFrame:CGRectMake(0.8*self.frame.size.width, 0.9*self.frame.size.height, 0.2*self.frame.size.width, 0.06*self.frame.size.height)];
    [self.divideCannonText setBackground:[UIImage imageNamed:@"textbox"]];
    self.divideCannonText.delegate = self;
    self.divideCannonText.textAlignment=NSTextAlignmentCenter;
    [self.view addSubview:self.divideCannonText];
    
    [self setupObjects];
}

-(void)setupObjects{
    //CGSize tam=CGSizeMake(0.1*self.frame.size.width, 0.1*self.frame.size.height);
    CGSize tam=CGSizeMake(0.2*self.frame.size.width, 0.2*self.frame.size.width);
    //CGPoint initial = CGPointMake(0.2*self.frame.size.width, self.frame.size.height-tam.height);
    CGPoint initial = CGPointMake(0.8*self.frame.size.width, self.frame.size.height-tam.height);
    NSInteger i=0, j=0;
    //MIRRORS
    [self setupObjectNamed:@MIRROR inLocation:CGRectMake(initial.x+i*tam.width, initial.y+j*tam.height, tam.width, tam.height) withAngle:0];
    j--;
    [self setupObjectNamed:@MIRROR inLocation:CGRectMake(initial.x+i*tam.width, initial.y+j*tam.height, tam.width, tam.height) withAngle:1];
    j--;
    [self setupObjectNamed:@MIRROR inLocation:CGRectMake(initial.x+i*tam.width, initial.y+j*tam.height, tam.width, tam.height) withAngle:2];
    j--;
    
    [self setupObjectNamed:@MIRROR inLocation:CGRectMake(initial.x+i*tam.width, initial.y+j*tam.height, tam.width, tam.height) withAngle:3];
    j--;
    
    //WALLS
    [self setupObjectNamed:@WALL inLocation:CGRectMake(initial.x+i*tam.width, initial.y+j*tam.height, tam.width, tam.height) withAngle:0];
    j--;
    [self setupObjectNamed:@WALL inLocation:CGRectMake(initial.x+i*tam.width, initial.y+j*tam.height, tam.width, tam.height) withAngle:2];
    j--;
    [self setupObjectNamed:@WALLBOX inLocation:CGRectMake(initial.x+i*tam.width, initial.y+j*tam.height-10, tam.width, tam.height) withAngle:0];
    
    j=0;
    tam=CGSizeMake(0.1*self.frame.size.height, 0.1*self.frame.size.height);
    initial = CGPointMake(0.2*self.frame.size.width, self.frame.size.height-tam.height);
    
    //RECEPTOR
    [self setupObjectNamed:@RECEPTOR inLocation:CGRectMake(initial.x+i*tam.width, initial.y+j*tam.height, tam.width, tam.height) withAngle:0];
    i++;
    
    //PORTAL
    [self setupObjectNamed:@PORTAL inLocation:CGRectMake(initial.x+i*tam.width, initial.y+j*tam.height, tam.width, tam.height) withAngle:0];
    i++;
    
    //PASSWORD
    [self setupObjectNamed:@KEY inLocation:CGRectMake(initial.x+i*tam.width, initial.y+j*tam.height, tam.width, tam.height) withAngle:0];
    i++;

}

-(void)setupObjectNamed:(NSString*)name inLocation:(CGRect)place withAngle:(NSInteger)angle{
    SKSpriteNode *nodeBox = [SKSpriteNode new];
    [nodeBox setSize:place.size];
    nodeBox.name=[NSString stringWithFormat:@"%@%ld",name,angle];
    nodeBox.position=CGPointMake(CGRectGetMidX(place),CGRectGetMidY(place));
    nodeBox.zPosition=10;
    
    SKSpriteNode *node = [SKSpriteNode spriteNodeWithImageNamed:name];
    node.xScale=place.size.width/node.size.width;
    node.yScale=node.xScale;
    node.name=name;
    node.zRotation=angle*M_PI/4;
    node.position=CGPointMake(CGRectGetMidX(place),CGRectGetMidY(place));
    [self addChild:nodeBox];
    [self addChild:node];
    [nodesDict setObject:node forKey:nodeBox.name];
}

@end
