package world;
import nape.phys.Body;

interface PhysicalLayer extends WorldLayer {
	
	public var body:Body;
	public function updatePhysObjects():Void;
}