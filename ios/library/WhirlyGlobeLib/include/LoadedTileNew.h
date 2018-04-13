/*
 *  LoadedTileNew.h
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 3/28/18.
 *  Copyright 2011-2018 Saildrone Inc.
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

#import <Foundation/Foundation.h>
#import <math.h>
#import "WhirlyVector.h"
#import "TextureGroup.h"
#import "Scene.h"
#import "DataLayer.h"
#import "LayerThread.h"
#import "GlobeMath.h"
#import "sqlhelpers.h"
#import "QuadTreeNew.h"
#import "SceneRendererES.h"

namespace WhirlyKit
{

/* Geometry settings passed to the tile generation method.
  */
class TileGeomSettings
{
public:
    TileGeomSettings();
    
    // Whether the geometry is centered in its middle with an offset
    bool useTileCenters;
    // Base color for the tiles
    RGBAColor color;
    // Shader to to use in rendering
    SimpleIdentity programID;
    // Samples to generate in X and Y
    int sampleX,sampleY;
    // If set, viewable range
    double minVis,maxVis;
    // The priority for the drawables
    int drawPriority;
    // If set, we'll just build lines for debugging
    bool lineMode;
    // If set, we'll include the elevation data
    bool includeElev;
};

class TileGeomManager;

/* Wraps a single tile that we've loaded into memory.
  */
class LoadedTileNew
{
public:
    LoadedTileNew(QuadTreeNew::Node &ident);
    
    // Build the drawable(s) to represent this one tile
    void makeDrawables(TileGeomManager *geomManage,TileGeomSettings &geomSettings,ChangeSet &changes);

    // Utility routine to build skirts around the edges
    void buildSkirt(BasicDrawable *draw,std::vector<Point3d> &pts,std::vector<TexCoord> &texCoords,double skirtFactor,bool haveElev,const Point3d &theCenter);

    // Enable associated drawables
    void enable(ChangeSet &changes);

    // Disable associated drawables
    void disable(ChangeSet &changes);

    // Generate commands to remove the associated drawables
    void removeDrawables(ChangeSet &changes);

    bool enabled;
    QuadTreeNew::Node ident;
    // Active drawable IDs associated with this tile
    SimpleIDSet drawIDs;
};
typedef std::shared_ptr<LoadedTileNew> LoadedTileNewRef;
typedef std::vector<LoadedTileNewRef> LoadedTileVec;
    
/** Tile Builder builds individual tile geometry for use elsewhere.
    This is just the geometry.  If you want textures on it, you need to do those elsewhere.
  */
class TileGeomManager
{
public:
    TileGeomManager();
    
    // Construct with the quad tree we're building off of, the coordinate system we're building from and the (valid) bounding box
    void setup(QuadTreeNew *quadTree,CoordSystemDisplayAdapter *coordAdapter,CoordSystem *coordSys,MbrD inMbr);
    
    // Keep track of nodes added, enabled and disabled
    class NodeChanges
    {
    public:
        LoadedTileVec addedTiles;
        LoadedTileVec enabledTiles;
        LoadedTileVec disabledTiles;
    };
    
    // Add the tiles list in the node set
    NodeChanges addTiles(TileGeomSettings &geomSettings,const QuadTreeNew::NodeSet &tiles,ChangeSet &changes);
    
    // Return a list of tiles corresponding to the IDs
    std::vector<LoadedTileNewRef> getTiles(const QuadTreeNew::NodeSet &tiles);
    
    // Return a single node
    LoadedTileNewRef getTile(QuadTreeNew::Node &ident);
    
    // Remove the tiles given, if they're being represented
    NodeChanges removeTiles(const QuadTreeNew::NodeSet &tiles,ChangeSet &changes);
    
    // Turn tiles on/off based on their childen
    void updateParents(ChangeSet &changes,LoadedTileVec &enabledNodes,LoadedTileVec &disabledNodes);
    
    QuadTreeNew *quadTree;
    CoordSystemDisplayAdapter *coordAdapter;
    
    // Coordinate system of the tiles (different from the scene)
    CoordSystem *coordSys;
    
    // Build geometry to the poles
    bool coverPoles;
    
    // Color overrides for poles, if present
    bool useNorthPoleColor,useSouthPoleColor;
    RGBAColor northPoleColor,southPoleColor;

    // Build the skirts for edge matching
    bool buildSkirts;
    
    // Bounding box of the whole area
    MbrD mbr;
    
    std::map<QuadTreeNew::Node,LoadedTileNewRef> tileMap;
};

}
