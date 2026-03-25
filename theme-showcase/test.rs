use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;

// Traits and generics
trait Fetchable {
    fn fetch(&self) -> Result<String, Box<dyn std::error::Error>>;
}

// Enums with associated data
#[derive(Debug, Clone)]
enum Status {
    Pending,
    Success(String),
    Failed(String),
    Timeout,
}

// Structs with lifetimes and generics
#[derive(Debug)]
struct WebScraper<'a> {
    urls: Vec<&'a str>,
    timeout: Duration,
    results: Arc<Mutex<HashMap<String, Status>>>,
}

impl<'a> WebScraper<'a> {
    fn new(urls: Vec<&'a str>) -> Self {
        Self {
            urls,
            timeout: Duration::from_secs(5),
            results: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    // Method with pattern matching and error handling
    fn scrape_concurrent(&self) -> Result<(), Box<dyn std::error::Error>> {
        let handles: Vec<_> = self.urls
            .iter()
            .map(|&url| {
                let results = Arc::clone(&self.results);
                let url_owned = url.to_string();
                
                thread::spawn(move || {
                    let status = match Self::fetch_url(&url_owned) {
                        Ok(content) => Status::Success(content),
                        Err(e) => Status::Failed(e.to_string()),
                    };
                    
                    if let Ok(mut map) = results.lock() {
                        map.insert(url_owned, status);
                    }
                })
            })
            .collect();

        // Join all threads
        for handle in handles {
            handle.join().map_err(|_| "Thread panicked")?;
        }

        Ok(())
    }

    // Associated function (static method)
    fn fetch_url(url: &str) -> Result<String, Box<dyn std::error::Error>> {
        // Simulate HTTP request
        thread::sleep(Duration::from_millis(100));
        
        if url.contains("invalid") {
            Err("Invalid URL".into())
        } else {
            Ok(format!("Content from {}", url))
        }
    }

    // Method with closure and iterator chains
    fn print_results(&self) {
        if let Ok(results) = self.results.lock() {
            results.iter()
                .filter(|(_, status)| matches!(status, Status::Success(_)))
                .for_each(|(url, status)| {
                    println!("✓ {}: {:?}", url, status);
                });
        }
    }
}

// Macro definition
macro_rules! time_it {
    ($expr:expr) => {{
        let start = std::time::Instant::now();
        let result = $expr;
        println!("Elapsed: {:?}", start.elapsed());
        result
    }};
}

// Main function with advanced features
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let urls = vec![
        "https://example.com",
        "https://rust-lang.org",
        "https://github.com",
        "https://invalid.test", // This will fail
    ];

    let scraper = WebScraper::new(urls);
    
    time_it!(scraper.scrape_concurrent())?;
    scraper.print_results();

    // Pattern matching with guards
    let test_values = vec![Some(42), None, Some(-1), Some(100)];
    for value in test_values {
        match value {
            Some(x) if x > 50 => println!("Large: {}", x),
            Some(x) if x < 0 => println!("Negative: {}", x),
            Some(x) => println!("Small positive: {}", x),
            None => println!("No value"),
        }
    }

    Ok(())
}
