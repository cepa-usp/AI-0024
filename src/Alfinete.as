package  
{
	import org.papervision3d.events.FileLoadEvent;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.parsers.DAE;
	import org.papervision3d.objects.primitives.Cone;
	import org.papervision3d.objects.primitives.Sphere;
	/**
	 * ...
	 * @author Alexandre
	 */
	public class Alfinete extends DisplayObject3D
	{
		var cabeca:Sphere;
		var ponta:Cone;
		var tachinha:DAE;
		
		public function Alfinete() 
		{
			//init();
			init2();
		}
		
		private function init2():void
		{
			tachinha = new DAE();
			tachinha.addEventListener(FileLoadEvent.LOAD_COMPLETE, loadTachinha);
			DAE(tachinha).load("assets/objects3d/tachinha.DAE");
		}
		
		private function loadTachinha(e:FileLoadEvent):void 
		{
			tachinha.removeEventListener(FileLoadEvent.LOAD_COMPLETE, loadTachinha);
			this.addChild(tachinha);
			tachinha.rotationX = -90;
			this.scale = 2;
		}
		
		private function init():void
		{
			var materialCabeca:ColorMaterial = new ColorMaterial(0xFF0000);
			var materialPonta:ColorMaterial = new ColorMaterial(0xC0C0C0);
			
			cabeca = new Sphere(materialCabeca, 5);
			ponta = new Cone(materialPonta, 3, 10);
			ponta.rotationX = 90;
			cabeca.z = -15;
			ponta.z = -5;
			//ponta.scale = 3;
			
			addChild(cabeca);
			addChild(ponta);
			
			//var plano:CartesianAxis3D2 = new CartesianAxis3D2();
			//addChild(plano);
			//plano.scale = 0.5;
		}
		
	}

}