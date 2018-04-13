/*
 *  QuadTileBuilder.mm
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 3/29/18.
 *  Copyright 2012-2018 Saildrone Inc
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#import "QuadTileBuilder.h"
#import "LoadedTileNew.h"

using namespace WhirlyKit;

@implementation WhirlyKitQuadTileBuilder
{
    WhirlyKitQuadDisplayLayerNew * __weak layer;
    
    TileGeomManager geomManage;
    TileGeomSettings geomSettings;
}

- (id)initWithCoordSys:(WhirlyKit::CoordSystem *)coordSys
{
    self = [super init];
    _coordSys = coordSys;
    
    return self;
}

- (void)setCoverPoles:(bool)coverPoles
{
    geomManage.coverPoles = coverPoles;
}

- (bool)coverPoles
{
    return geomManage.coverPoles;
}

- (void)setEdgeMatching:(bool)edgeMatch
{
    geomManage.buildSkirts = edgeMatch;
}

- (bool)edgeMatching
{
    return geomManage.buildSkirts;
}

- (WhirlyKit::LoadedTileNewRef)getLoadedTile:(WhirlyKit::QuadTreeNew::Node)ident
{
    return geomManage.getTile(ident);
}

// MARK: WhirlyKitQuadLoaderNew delegate

- (void)setQuadLayer:(WhirlyKitQuadDisplayLayerNew *)inLayer
{
    layer = inLayer;
    MbrD mbr = MbrD([layer.dataStructure validExtents]);
    geomManage.setup(layer.quadtree, layer.scene->getCoordAdapter(),_coordSys,mbr);
    
    [_delegate setQuadBuilder:self layer:layer];
}

- (void)quadDisplayLayer:(WhirlyKitQuadDisplayLayerNew *)layer loadTiles:(const QuadTreeNew::NodeSet &)tiles
{
    ChangeSet changes;
    
    // Have the geometry manager add the tiles and deal with changes
    auto tileChanges = geomManage.addTiles(geomSettings, tiles, changes);
    
    // Tell the delegate to start loading those tiles
    [_delegate quadBuilder:self loadTiles:tileChanges.addedTiles changes:changes];
    
    // Enable/disable any tiles as a result
    [_delegate quadBuilder:self enableTiles:tileChanges.enabledTiles changes:changes];
    [_delegate quadBuilder:self disableTiles:tileChanges.disabledTiles changes:changes];
    
    if (_debugMode)
    {
        NSLog(@"----- Tiles to add ------");
        for (auto tile : tiles)
            NSLog(@"  %d: (%d,%d)",tile.level,tile.x,tile.y);
        NSLog(@"----- Nodes to enable ------");
        for (auto tile : tileChanges.enabledTiles)
            NSLog(@"  %d: (%d,%d)",tile->ident.level,tile->ident.x,tile->ident.y);
        NSLog(@"----- Nodes to disable ------");
        for (auto tile : tileChanges.disabledTiles)
            NSLog(@"  %d: (%d,%d)",tile->ident.level,tile->ident.x,tile->ident.y);
        NSLog(@"----- ------------- ------");
    }

    // Flush out any visual changes
    [layer.layerThread addChangeRequests:changes];
}

- (void)quadDisplayLayer:(WhirlyKitQuadDisplayLayerNew *)layer unLoadTiles:(const QuadTreeNew::NodeSet &)tiles
{
    ChangeSet changes;

    // Remove the old tiles
    auto oldTiles = geomManage.getTiles(tiles);
    [_delegate quadBuilder:self unLoadTiles:oldTiles changes:changes];
    auto tileChanges = geomManage.removeTiles(tiles, changes);
    
    // Enable/disable any tiles as a result
    [_delegate quadBuilder:self enableTiles:tileChanges.enabledTiles changes:changes];
    [_delegate quadBuilder:self disableTiles:tileChanges.disabledTiles changes:changes];
    
    if (_debugMode)
    {
        NSLog(@"----- Tiles to remove ------");
        for (auto tile : tiles)
            NSLog(@"  %d: (%d,%d)",tile.level,tile.x,tile.y);
        NSLog(@"----- Nodes to enable ------");
        for (auto tile : tileChanges.enabledTiles)
            NSLog(@"  %d: (%d,%d)",tile->ident.level,tile->ident.x,tile->ident.y);
        NSLog(@"----- Nodes to disable ------");
        for (auto tile : tileChanges.disabledTiles)
            NSLog(@"  %d: (%d,%d)",tile->ident.level,tile->ident.x,tile->ident.y);
        NSLog(@"----- ------------- ------");
    }

    [layer.layerThread addChangeRequests:changes];

}

@end