package world;

enum WorldLayerType {
	TILE;
	OBJECT;
	COLLISION;
	OTHER;
}

interface WorldLayer {
	
	public var layerType:WorldLayerType;
	public var world:World;
	
}