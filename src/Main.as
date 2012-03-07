package  
{
	import cepa.utils.ToolTip;
	import fl.transitions.easing.None;
	import fl.transitions.Tween;
	import flash.display.BitmapData;
	import flash.display.Stage;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.text.TextField;
	import flash.utils.Timer;
	import org.papervision3d.core.math.Number3D;
	import org.papervision3d.core.utils.Mouse3D;
	import org.papervision3d.events.InteractiveScene3DEvent;
	import org.papervision3d.materials.BitmapFileMaterial;
	import org.papervision3d.materials.BitmapMaterial;
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.materials.shaders.FlatShader;
	import org.papervision3d.materials.shaders.GouraudShader;
	import org.papervision3d.materials.shaders.ShadedMaterial;
	import org.papervision3d.objects.DisplayObject3D;
	import org.papervision3d.objects.primitives.Cylinder;
	import org.papervision3d.objects.primitives.Sphere;
	import org.papervision3d.view.BasicView;
	import org.papervision3d.view.layer.ViewportLayer;
	
	/**
	 * ...
	 * @author Alexandre
	 */
	public class Main extends BasicView
	{
		/**
		 * @private
		 * Posição do click na tela.
		 */
		private var clickPoint:Point =  new Point();
		
		/**
		 * @private
		 * Utilizado para cálculo da rotação da câmera.
		 */
		public var theta:Number;
		
		/**
		 * @private
		 * Utilizado para cálculo da rotação da câmera.
		 */
		public var phi:Number; 
		
		/**
		 * @private
		 * Ponto onde o mouse foi solto.
		 * Utilizado para movimentação da câmera.
		 */
		private var upPoint:Point = new Point();
		
		/**
		 * @private
		 * Esfera que será usada como mapa.
		 */
		private var sphere:Sphere;
		
		/**
		 * @private
		 * Mouse3D usado para calcular a posição 3D no mapa.
		 */
		private var mouse3D:Mouse3D;
		
		/**
		 * @private
		 * Vetor que representa a direção y da câmera, impedindo que ela rotacione ao ficar invertida (de ponta cabeça).
		 */
		private var upVector:Number3D;
		
		/**
		 * @private
		 * Fator de multiplicação de distância da câmera.
		 */
		public var distance:Number = 1000;
		
		/**
		 * @private
		 * Alfinete que representa o local do click feito pelo usuário.
		 */
		private var alfineteClick:Alfinete;
		
		/*
		 * Filtro de conversão para tons de cinza.
		 */
		private const GRAYSCALE_FILTER:ColorMatrixFilter = new ColorMatrixFilter([
			0.2225, 0.7169, 0.0606, 0, 0,
			0.2225, 0.7169, 0.0606, 0, 0,
			0.2225, 0.7169, 0.0606, 0, 0,
			0.0000, 0.0000, 0.0000, 1, 0
		]);
		
		private var latitudeTitanic:Number = 42;
		private var longitudeTitanic:Number = -48;
		
		private var latitudeClick:Number;
		private var longitudeClick:Number;
		
		private var orientacoesScreen:InstScreen;
		private var creditosScreen:AboutScreen;
		private var feedbackScreen:FeedBackScreen;
		
		public function Main() 
		{
			super(700, 480, false, true);
			if (stage) init(null);
			else addEventListener(Event.ADDED_TO_STAGE, init);
			
		}
		
		/**
		 * @private
		 * Inicia atividade.
		 */
		private function init(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			this.scrollRect = new Rectangle(0, 0, 700, 500);
			
			creditosScreen = new AboutScreen();
			addChild(creditosScreen);
			orientacoesScreen = new InstScreen();
			addChild(orientacoesScreen);
			feedbackScreen = new FeedBackScreen();
			addChild(feedbackScreen);
			
			inicializaParametros();
			startRendering();
			createSphere();
			adicionaListeners();
			
			//stage.displayState = StageDisplayState.FULL_SCREEN;
			stage.scaleMode = StageScaleMode.SHOW_ALL;
			
			interactiveViewPort();
			interactiveMouse();
			rotating(null);
			setChildIndex(bordaAtividade, numChildren - 1);
		}
		
		/**
		 * @private
		 * Inicializa os parâmetros necessários a atividade.
		 */
		private function inicializaParametros():void
		{
			btOk.filters = [GRAYSCALE_FILTER];
			btOk.mouseEnabled = false;
			btOk.alpha = 0.5;
			//btCancel.visible = false;
			
			//latText.visible = false;
			//longText.visible = false;
			//latitude.visible = false;
			//longitude.visible = false;
		}
		
		/**
		 * Adiciona eventListener aos objetos no stage.
		 */
		private function adicionaListeners():void
		{
			btOk.addEventListener(MouseEvent.CLICK, verificaCoordenadas);
			//btCancel.addEventListener(MouseEvent.CLICK, calcelHandler);
			
			botoes.tutorialBtn.addEventListener(MouseEvent.CLICK, iniciaTutorial);
			botoes.orientacoesBtn.addEventListener(MouseEvent.CLICK, openOrientacoes);
			botoes.resetButton.addEventListener(MouseEvent.CLICK, reset);
			botoes.creditos.addEventListener(MouseEvent.CLICK, openCreditos);
			
			stage.addEventListener(MouseEvent.MOUSE_DOWN, initRotation);
			
			createToolTips();
		}
		
		private function openOrientacoes(e:MouseEvent):void 
		{
			orientacoesScreen.openScreen();
			setChildIndex(orientacoesScreen, numChildren - 1);
			setChildIndex(bordaAtividade, numChildren - 1);
		}
		
		private function openCreditos(e:MouseEvent):void 
		{
			creditosScreen.openScreen();
			setChildIndex(creditosScreen, numChildren - 1);
			setChildIndex(bordaAtividade, numChildren - 1);
		}
		
		private function createToolTips():void 
		{
			var infoTT:ToolTip = new ToolTip(botoes.creditos, "Créditos", 12, 0.8, 100, 0.6, 0.1);
			var instTT:ToolTip = new ToolTip(botoes.orientacoesBtn, "Orientações", 12, 0.8, 100, 0.6, 0.1);
			var resetTT:ToolTip = new ToolTip(botoes.resetButton, "Reiniciar", 12, 0.8, 100, 0.6, 0.1);
			var intTT:ToolTip = new ToolTip(botoes.tutorialBtn, "Reiniciar tutorial", 12, 0.8, 150, 0.6, 0.1);
			
			var finalizaTT:ToolTip = new ToolTip(btOk, "Finaliza atividade", 12, 0.8, 200, 0.6, 0.1);
			
			addChild(infoTT);
			addChild(instTT);
			addChild(resetTT);
			addChild(intTT);
			addChild(finalizaTT);
		}
		
		private function verificaCoordenadas(e:MouseEvent):void 
		{
			if (Math.abs(latitudeTitanic - latitudeClick) <= 2 && Math.abs(longitudeTitanic - longitudeClick) <= 2)
			{
				feedbackScreen.setText("Parabéns!\nVocê encontrou o Titanic!");
			}
			else
			{
				feedbackScreen.setText("Procure novamente...");
			}
		}
		
		private function reset(e:MouseEvent):void 
		{
			inicializaParametros();
			
			if (alfineteClick != null)
			{
				scene.removeChild(alfineteClick);
				alfineteClick = null;
			}
			
			upPoint.x = -1260;
			upPoint.y = 450;
			rotating(null);
		}
		
		/**
		 * @private
		 * Torna o viewport interativo.
		 */
		private function interactiveViewPort():void
		{
			viewport.interactive = true;
			
			camera.target = null;
			upPoint.x = -1260;
			upPoint.y = 450;
		}
		
		/**
		 * @private
		 * habilita o Mouse3D e instancia a variável mouse3D.
		 */
		private function interactiveMouse():void
		{
			//Habilita o Mouse3D.
			Mouse3D.enabled = true;
			
			//Cria o mouse3D.
			mouse3D = viewport.interactiveSceneManager.mouse3D;
			
			//alfineteClick = new Alfinete();
			if (alfineteClick == null)
			{
				alfineteClick = new Alfinete();
				alfineteClick.copyTransform(mouse3D);
				//scene.addChild(alfineteClick);
			}
		}
		
		/**
		 * @private
		 * Cria a esfera.
		 */
		private function createSphere():void
		{
			//Cria um bitmapData com a imagem adicionada.
			var earthBmp:BitmapData = new EarthMap();
			//Cria um BitmapMaterial com o bitmap criado com a imagem.
			var earthMaterial:BitmapMaterial = new BitmapMaterial(earthBmp);
			//Torna o BitmapMatrial interativo(passível de clicks).
			earthMaterial.interactive = true;
			
			//Cria um shader.
			//var shader:GouraudShader = new GouraudShader(null, 0xFFFFFF, 0x000000);
			var shader:FlatShader = new FlatShader(null, 0xFFFFFF, 0x000000);
			
			//Cria um shadedMaterial para ser usado como material da esfera.
			var shadedMaterial:ShadedMaterial = new ShadedMaterial(earthMaterial, shader);
			shadedMaterial.interactive = true;
			
			//Cria a esfera com o material dado(earthMaterial ou shadedMaterial).
			//sphere = new Sphere(earthMaterial, 400, 24, 18);
			sphere = new Sphere(shadedMaterial, 480, 36, 18);
			
			scene.addChild(sphere);
			
			//addEventListener(MouseEvent.MOUSE_DOWN, clickHandler);
			sphere.addEventListener(InteractiveScene3DEvent.OBJECT_CLICK, sphereClickHandler); 
		}
		
		/**
		 * @private
		 * Trata o clique na esfera.
		 */
		private function sphereClickHandler(e:InteractiveScene3DEvent):void 
		{
			if (alfineteClick != null) 
			{
				scene.removeChild(alfineteClick);
				alfineteClick = null;
			}
			
			alfineteClick = new Alfinete();
			alfineteClick.copyTransform(mouse3D);
			scene.addChild(alfineteClick);
			
			var phiRotation:Number = Math.acos(mouse3D.y / 400) * 180 / Math.PI;
			var thetaRotation:Number = Math.atan2(mouse3D.z, mouse3D.x) * 180 / Math.PI;
			
			var raio:Number = Math.sqrt(Math.pow(mouse3D.x, 2)+Math.pow(mouse3D.y, 2)+Math.pow(mouse3D.z, 2));
			
			var phi:Number = 90 - (Math.acos(mouse3D.y / raio)*180/Math.PI);
			
			var theta:Number = Math.atan2(mouse3D.z, mouse3D.x)*180/Math.PI + 180;
			
			var latitudeGraus:int = Math.floor(phi);
			var latitudeMin:int = Math.floor((phi - latitudeGraus) * 60);
			var latitudeSeg:int = Math.round(((phi - latitudeGraus) * 60 - latitudeMin) * 60);
			
			//trace("latitude: " + latitudeGraus + "º " + latitudeMin + "\' " + latitudeSeg + "\"");
			//latitude.text = String(latitudeGraus) + "º " + String(latitudeMin) + "\' " + String(latitudeSeg) + "\"";
			
			var longitudeGraus:int;
			var longitudeMin:int;
			var longitudeSeg:int;
			
			if (theta > 180) 
			{
				longitudeGraus = Math.floor(theta) - 360;
				var longitudeGrausAux:int = Math.floor(theta);
				longitudeMin = Math.floor((theta - longitudeGrausAux) * 60);
				longitudeSeg = Math.round(((theta - longitudeGrausAux) * 60 - longitudeMin) * 60);
			}
			else 
			{
				longitudeGraus = Math.floor(theta);
				longitudeMin = Math.floor((theta - longitudeGraus) * 60);
				longitudeSeg = Math.round(((theta - longitudeGraus) * 60 - longitudeMin) * 60);
			}
			
			//trace("longitude: " + longitudeGraus + "º " + longitudeMin + "\' " + longitudeSeg + "\"");
			//longitude.text = String(longitudeGraus) + "º " + String(longitudeMin) + "\' " + String(longitudeSeg) + "\""
			
			latitudeClick = latitudeGraus;
			longitudeClick = longitudeGraus;
			
			btOk.filters = [];
			btOk.mouseEnabled = true;
			btOk.alpha = 1;
			//btCancel.visible = true;
			
			//latText.visible = true;
			//longText.visible = true;
			//latitude.visible = true;
			//longitude.visible = true;
			
		}
		
		/**
		 * @private
		 * Inicia o processo de rotação da câmera.
		 */
		private function initRotation(e:MouseEvent):void 
		{
			//if (e.target is Stage)
			//{
				stage.addEventListener(Event.ENTER_FRAME, rotating);
				stage.addEventListener(MouseEvent.MOUSE_UP, stopRotating);
				clickPoint.x = stage.mouseX;
				clickPoint.y = stage.mouseY;
			//}
		}
		
		/**
		 * @private
		 * Rotação da câmera.
		 */
		private function rotating(e:Event):void 
		{
			if(e != null){
				theta = ((upPoint.x - (stage.mouseX - clickPoint.x)) / stage.stageWidth * 100) * Math.PI / 180;// % 360; 
				phi = ((upPoint.y - (stage.mouseY - clickPoint.y)) / stage.stageHeight * 100 ) * Math.PI / 180;// % 360;
			}else {
				theta = ((upPoint.x) / stage.stageWidth * 100) * Math.PI / 180;// % 360; 
				phi = ((upPoint.y) / stage.stageHeight * 100 ) * Math.PI / 180;// % 360;
			}
			
			if (theta == 0) theta = 0.001;
			if (phi == 0) phi = 0.001;
			
			camera.x = distance * Math.cos(theta) * Math.sin(phi); 
			camera.z = distance * Math.sin(theta) * Math.sin(phi); 
			camera.y = distance * Math.cos(phi); 
			
			
			if (Math.sin(phi) < 0) upVector = new Number3D(0, -1, 0); 
			else upVector = new Number3D(0, 1, 0);
			camera.lookAt(sphere , upVector);
			
		}
		
		/**
		 * @private
		 * Para a rotação da câmera.
		 */
		private function stopRotating(e:MouseEvent):void 
		{
			stage.removeEventListener(Event.ENTER_FRAME, rotating);
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopRotating);
			
			upPoint.x = upPoint.x - (stage.mouseX - clickPoint.x);
			upPoint.y = upPoint.y - (stage.mouseY - clickPoint.y);
		}
		
		
		//---------------------------------- Tutorial --------------------------------------//
		
		private var balao:CaixaTexto;
		private var pointsTuto:Array;
		private var tutoBaloonPos:Array;
		private var tutoPos:int;
		private var tutoSequence:Array = ["Estas placas de Petri contém três espécies distintas de bactérias.", 
										  "Classifique as bactérias arrastando os rótulos para as placas de Petri.",
										  "O tubo de ensaio contém um líquido propício à proliferação das três bactérias.",
										  "Esta escala indica a distribuição de oxigênio no tubo de ensaio: quanto mais verde, mais oxigênio há naquela altura do tubo.",
										  "Você pode arrastar uma ou mais bactérias para dentro do tubo de ensaio.",
										  "Pressione este botão para trocar o tubo de ensaio e começar uma nova experiência."];
		
		private function iniciaTutorial(e:MouseEvent = null):void 
		{
			tutoPos = 0;
			if(balao == null){
				balao = new CaixaTexto(true);
				addChild(balao);
				balao.visible = false;
				
				pointsTuto = 	[new Point(),
								new Point(),
								new Point(),
								new Point(),
								new Point(),
								new Point()];
								
				tutoBaloonPos = [[CaixaTexto.BOTTON, CaixaTexto.CENTER],
								[CaixaTexto.TOP, CaixaTexto.CENTER],
								[CaixaTexto.LEFT, CaixaTexto.FIRST],
								[CaixaTexto.LEFT, CaixaTexto.CENTER],
								[CaixaTexto.BOTTON, CaixaTexto.CENTER],
								[CaixaTexto.LEFT, CaixaTexto.LAST]];
			}
			balao.removeEventListener(Event.CLOSE, closeBalao);
			
			balao.setText(tutoSequence[tutoPos], tutoBaloonPos[tutoPos][0], tutoBaloonPos[tutoPos][1]);
			balao.setPosition(pointsTuto[tutoPos].x, pointsTuto[tutoPos].y);
			balao.addEventListener(Event.CLOSE, closeBalao);
			balao.visible = true;
		}
		
		private function closeBalao(e:Event):void 
		{
			tutoPos++;
			if (tutoPos >= tutoSequence.length) {
				balao.removeEventListener(Event.CLOSE, closeBalao);
				balao.visible = false;
				//tutoPhase = false;
			}else {
				balao.setText(tutoSequence[tutoPos], tutoBaloonPos[tutoPos][0], tutoBaloonPos[tutoPos][1]);
				balao.setPosition(pointsTuto[tutoPos].x, pointsTuto[tutoPos].y);
			}
		}
	}

}