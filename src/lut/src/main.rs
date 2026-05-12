use std::fs;

fn main() -> std::io::Result<()> {
    let mut content = "".to_string();
    
    let mut x: u16 = 315;
    let mut y: u16 = 315;
    
    let x_act = (x as f32 - 315.0) / 4.0; 
    let y_act = (y as f32 - 315.0) / 4.0; 
    
    let angle = y_act.atan2(x_act).to_degrees();
    
    println!("{angle}");
    
    fs::write("output.txt", content)?;
    Ok(())
}