package alphatab.rendering.glyphs;
import alphatab.model.AccentuationType;
import alphatab.model.Beat;
import alphatab.model.Duration;
import alphatab.model.GraceType;
import alphatab.model.HarmonicType;
import alphatab.model.Note;
import alphatab.model.SlideType;
import alphatab.platform.ICanvas;
import alphatab.platform.model.Color;
import alphatab.rendering.Glyph;
import alphatab.rendering.layout.ScoreLayout;
import alphatab.rendering.ScoreBarRenderer;
import alphatab.rendering.utils.BeamingHelper;

class ScoreBeatGlyph extends BeatGlyphBase
					implements ISupportsFinalize
{
	private var _ties:Array<Glyph>;

	public var noteHeads : ScoreNoteChordGlyph;
	public var restGlyph : RestGlyph;

	public var beamingHelper:BeamingHelper;

	public function new() 
	{
        super();
	}
	
	public function finalizeGlyph(layout:ScoreLayout)
	{
		if (!container.beat.isRest()) 
		{
			noteHeads.updateBeamingHelper(container.x + x);
		}
	}
	
	public override function applyGlyphSpacing(spacing:Int):Void 
	{
		super.applyGlyphSpacing(spacing);
		// TODO: we need to tell the beaming helper the position of rest beats
		if (!container.beat.isRest()) 
		{
			noteHeads.updateBeamingHelper(container.x + x);
		}
	}
		
	public override function doLayout():Void 
	{
		// create glyphs
        if (!container.beat.isEmpty)
        {
            if (!container.beat.isRest())
            {		
                //
                // Note heads
                //
                noteHeads = new ScoreNoteChordGlyph();
                noteHeads.beat = container.beat;
                noteHeads.beamingHelper = beamingHelper;
                noteLoop( function(n) {
                    createNoteGlyph(n);
                });
                addGlyph(noteHeads);			
                
                //
                // Note dots
                //
                for (i in 0 ... container.beat.dots)
                {
                    var group = new GlyphGroup();
                    noteLoop( function (n) {
                        createBeatDot(n, group);                    
                    });
                    addGlyph(group);
                }
            }
            else
            {
                var line = 0;
                var offset = 0;
            
                switch(container.beat.duration)
                {
                    case Whole:         
                        line = 4;
                    case Half:          
                        line = 5;
                    case Quarter:       
                        line = 7;
                        offset = -2;
                    case Eighth:        
                        line = 8;
                    case Sixteenth:     
                        line = 8;
                    case ThirtySecond:  
                        line = 8;
                    case SixtyFourth:   
                        line = 8;
                }
                
                var sr = cast(renderer, ScoreBarRenderer);
                var y = sr.getScoreY(line, offset);

                addGlyph(new RestGlyph(0, y, container.beat.duration));
            }
        }
		
		super.doLayout();
		if (noteHeads != null)
		{
			noteHeads.updateBeamingHelper(x);
		}
	}
	
    private function createBeatDot(n:Note, group:GlyphGroup)
    {			
		var sr = cast(renderer, ScoreBarRenderer);
        group.addGlyph(new CircleGlyph(0, sr.getScoreY(sr.getNoteLine(n), Std.int(2*getScale())), 1.5 * getScale()));
    }

	private function createNoteGlyph(n:Note) 
    {
		var sr = cast(renderer, ScoreBarRenderer);
        var noteHeadGlyph:Glyph;
		var isGrace = container.beat.graceType != GraceType.None;
		if (n.isDead) 
		{
            noteHeadGlyph = new DeadNoteHeadGlyph(0, 0, isGrace);
		}
        else if (n.harmonicType == HarmonicType.None)
        {
            noteHeadGlyph = new NoteHeadGlyph(0, 0, n.beat.duration, isGrace);
        }
        else
        {
            noteHeadGlyph = new DiamondNoteHeadGlyph(0, 0, isGrace);
        }
		
        // calculate y position
        var line = sr.getNoteLine(n);
        
        noteHeadGlyph.y = sr.getScoreY(line, -1);
        noteHeads.addNoteGlyph(noteHeadGlyph, n, line);
        
        if (n.isStaccato && !noteHeads.beatEffects.exists("STACCATO"))
        {
            noteHeads.beatEffects.set("STACCATO",  new CircleGlyph(0, 0, 1.5));
        }
        
        if (n.accentuated == AccentuationType.Normal && !noteHeads.beatEffects.exists("ACCENT"))
        {
            noteHeads.beatEffects.set("ACCENT",  new AccentuationGlyph(0, 0, AccentuationType.Normal));
        }
        if (n.accentuated == AccentuationType.Heavy && !noteHeads.beatEffects.exists("HACCENT"))
        {
            noteHeads.beatEffects.set("HACCENT",  new AccentuationGlyph(0, 0, AccentuationType.Heavy));
        }
    }
}