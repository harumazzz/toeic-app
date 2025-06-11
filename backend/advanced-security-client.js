/**
 * Advanced Security Client Library for TOEIC App
 * Provides enhanced security headers beyond JWT tokens
 * Compatible with WebAssembly and Web Workers
 */

class AdvancedSecurityClient {
    constructor(config = {}) {
        this.config = {
            secretKey: config.secretKey || '', // Should be provided by server on login
            baseURL: config.baseURL || '',
            wasmEnabled: config.wasmEnabled || false,
            webWorkerEnabled: config.webWorkerEnabled || false,
            securityLevel: config.securityLevel || 2,
            debug: config.debug || false,
            ...config
        };
        
        this.isWasmEnvironment = this.detectWasmEnvironment();
        this.isWebWorkerEnvironment = this.detectWebWorkerEnvironment();
        
        if (this.config.debug) {
            console.log('[AdvancedSecurity] Initialized with config:', {
                wasmEnabled: this.config.wasmEnabled,
                webWorkerEnabled: this.config.webWorkerEnabled,
                isWasm: this.isWasmEnvironment,
                isWorker: this.isWebWorkerEnvironment
            });
        }
    }

    /**
     * Detect if running in WebAssembly environment
     */
    detectWasmEnvironment() {
        if (typeof WebAssembly !== 'undefined') {
            // Check if we're in a WASM context by looking at the stack trace
            try {
                const stack = new Error().stack;
                return stack && stack.includes('wasm');
            } catch (e) {
                return false;
            }
        }
        return false;
    }

    /**
     * Detect if running in Web Worker environment
     */
    detectWebWorkerEnvironment() {
        return typeof importScripts === 'function' && 
               typeof WorkerGlobalScope !== 'undefined' && 
               self instanceof WorkerGlobalScope;
    }

    /**
     * Generate all required security headers for a request
     */
    async generateSecurityHeaders(method, path, additionalData = {}) {
        const timestamp = Math.floor(Date.now() / 1000);
        const nonce = this.generateNonce();
        
        const headers = {};

        try {
            // 1. Generate request timestamp
            headers['X-Request-Timestamp'] = timestamp.toString();

            // 2. Generate request nonce
            headers['X-Request-Nonce'] = nonce;

            // 3. Generate security token
            headers['X-Security-Token'] = await this.generateSecurityToken(timestamp, nonce);

            // 4. Generate client signature
            headers['X-Client-Signature'] = await this.generateClientSignature(method, path, timestamp);

            // 5. Set security level
            headers['X-Security-Level'] = this.config.securityLevel.toString();

            // 6. Generate browser fingerprint
            headers['X-Browser-Fingerprint'] = await this.generateBrowserFingerprint();

            // 7. Generate origin validation
            headers['X-Origin-Validation'] = await this.generateOriginValidation();

            // 8. Add WASM/WebWorker specific headers if applicable
            if (this.isWasmEnvironment && this.config.wasmEnabled) {
                headers['X-WASM-Mode'] = await this.generateWasmModeHeader();
            }

            if (this.isWebWorkerEnvironment && this.config.webWorkerEnabled) {
                headers['X-Worker-Context'] = await this.generateWorkerContextHeader();
            }

            // 9. Add encrypted payload header if sensitive data
            if (additionalData.sensitive) {
                headers['X-Encrypted-Payload'] = 'true';
            }

            if (this.config.debug) {
                console.log('[AdvancedSecurity] Generated headers:', Object.keys(headers));
            }

            return headers;

        } catch (error) {
            console.error('[AdvancedSecurity] Error generating headers:', error);
            throw new Error('Failed to generate security headers');
        }
    }

    /**
     * Generate security token (timestamp.nonce.signature)
     */
    async generateSecurityToken(timestamp, nonce) {
        const message = `${timestamp}.${nonce}`;
        const signature = await this.generateHMACSignature(message);
        return `${message}.${signature}`;
    }

    /**
     * Generate client signature
     */
    async generateClientSignature(method, path, timestamp) {
        const userAgent = this.getUserAgent();
        const message = `${method}|${path}|${timestamp}|${userAgent}`;
        return await this.generateHMACSignature(message);
    }

    /**
     * Generate browser fingerprint
     */
    async generateBrowserFingerprint() {
        const components = [];

        try {
            // Screen resolution
            if (typeof screen !== 'undefined') {
                components.push(`screen:${screen.width}x${screen.height}`);
            }

            // Timezone
            components.push(`tz:${Intl.DateTimeFormat().resolvedOptions().timeZone}`);

            // Language
            components.push(`lang:${navigator.language || 'unknown'}`);

            // Platform
            if (navigator.platform) {
                components.push(`platform:${navigator.platform}`);
            }

            // Hardware concurrency
            if (navigator.hardwareConcurrency) {
                components.push(`cores:${navigator.hardwareConcurrency}`);
            }

            // Canvas fingerprint (simple version)
            const canvasFingerprint = await this.generateCanvasFingerprint();
            if (canvasFingerprint) {
                components.push(`canvas:${canvasFingerprint}`);
            }

        } catch (error) {
            if (this.config.debug) {
                console.warn('[AdvancedSecurity] Error generating fingerprint component:', error);
            }
        }

        const fingerprint = components.join('|');
        return await this.generateHMACSignature(fingerprint);
    }

    /**
     * Generate simple canvas fingerprint
     */
    async generateCanvasFingerprint() {
        try {
            if (typeof document === 'undefined' || this.isWebWorkerEnvironment) {
                return 'no-canvas';
            }

            const canvas = document.createElement('canvas');
            const ctx = canvas.getContext('2d');
            
            // Draw some basic shapes
            ctx.fillStyle = 'rgb(200,0,0)';
            ctx.fillRect(10, 10, 50, 50);
            ctx.fillStyle = 'rgba(0, 0, 200, 0.5)';
            ctx.fillRect(30, 30, 50, 50);
            
            // Get image data and hash it
            const imageData = canvas.toDataURL();
            return await this.simpleHash(imageData);
        } catch (error) {
            return 'canvas-error';
        }
    }

    /**
     * Generate origin validation token
     */
    async generateOriginValidation() {
        let origin = 'unknown';
        
        try {
            if (typeof location !== 'undefined') {
                origin = location.origin;
            } else if (this.isWebWorkerEnvironment) {
                // In web worker, use self.location if available
                origin = self.location ? self.location.origin : 'worker-context';
            } else if (this.isWasmEnvironment) {
                origin = 'wasm-context';
            }
        } catch (error) {
            origin = 'detection-error';
        }

        const payload = `origin:${origin}:${Date.now()}`;
        const signature = await this.generateHMACSignature(payload);
        return `${this.base64Encode(payload)}.${signature}`;
    }

    /**
     * Generate WASM mode header
     */
    async generateWasmModeHeader() {
        const wasmInfo = {
            version: '1.0',
            context: 'wasm',
            timestamp: Date.now(),
            features: this.getWasmFeatures()
        };

        const payload = JSON.stringify(wasmInfo);
        const signature = await this.generateHMACSignature(payload);
        return `${this.base64Encode(payload)}.${signature}`;
    }

    /**
     * Generate web worker context header
     */
    async generateWorkerContextHeader() {
        const workerInfo = {
            type: 'webworker',
            timestamp: Date.now(),
            scope: typeof self !== 'undefined' ? 'global' : 'unknown'
        };

        const payload = JSON.stringify(workerInfo);
        const signature = await this.generateHMACSignature(payload);
        return `${this.base64Encode(payload)}.${signature}`;
    }

    /**
     * Get WebAssembly features
     */
    getWasmFeatures() {
        const features = [];
        
        try {
            if (typeof WebAssembly !== 'undefined') {
                features.push('basic');
                
                if (WebAssembly.instantiateStreaming) {
                    features.push('streaming');
                }
                
                if (WebAssembly.Memory) {
                    features.push('memory');
                }
            }
        } catch (error) {
            // Ignore errors
        }

        return features;
    }

    /**
     * Generate HMAC signature using Web Crypto API
     */
    async generateHMACSignature(message) {
        try {
            // Use Web Crypto API if available
            if (typeof crypto !== 'undefined' && crypto.subtle) {
                const encoder = new TextEncoder();
                const key = await crypto.subtle.importKey(
                    'raw',
                    encoder.encode(this.config.secretKey),
                    { name: 'HMAC', hash: 'SHA-256' },
                    false,
                    ['sign']
                );

                const signature = await crypto.subtle.sign(
                    'HMAC',
                    key,
                    encoder.encode(message)
                );

                return Array.from(new Uint8Array(signature))
                    .map(b => b.toString(16).padStart(2, '0'))
                    .join('');
            } else {
                // Fallback to simple hash for environments without Web Crypto API
                return await this.simpleHash(this.config.secretKey + message);
            }
        } catch (error) {
            if (this.config.debug) {
                console.warn('[AdvancedSecurity] Crypto API unavailable, using fallback:', error);
            }
            return await this.simpleHash(this.config.secretKey + message);
        }
    }

    /**
     * Simple hash function fallback
     */
    async simpleHash(str) {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            const char = str.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32-bit integer
        }
        return Math.abs(hash).toString(16);
    }

    /**
     * Generate random nonce
     */
    generateNonce() {
        const array = new Uint8Array(16);
        if (typeof crypto !== 'undefined' && crypto.getRandomValues) {
            crypto.getRandomValues(array);
        } else {
            // Fallback for environments without crypto
            for (let i = 0; i < array.length; i++) {
                array[i] = Math.floor(Math.random() * 256);
            }
        }
        return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
    }

    /**
     * Get user agent string
     */
    getUserAgent() {
        try {
            if (typeof navigator !== 'undefined' && navigator.userAgent) {
                return navigator.userAgent;
            } else if (this.isWebWorkerEnvironment) {
                return 'WebWorker/1.0';
            } else if (this.isWasmEnvironment) {
                return 'WebAssembly/1.0';
            }
            return 'Unknown/1.0';
        } catch (error) {
            return 'Error/1.0';
        }
    }

    /**
     * Base64 encode (compatible with web workers)
     */
    base64Encode(str) {
        try {
            if (typeof btoa !== 'undefined') {
                return btoa(str);
            } else {
                // Simple base64 implementation for environments without btoa
                const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
                let result = '';
                let i = 0;
                
                while (i < str.length) {
                    const a = str.charCodeAt(i++);
                    const b = i < str.length ? str.charCodeAt(i++) : 0;
                    const c = i < str.length ? str.charCodeAt(i++) : 0;
                    
                    const bitmap = (a << 16) | (b << 8) | c;
                    
                    result += chars.charAt((bitmap >> 18) & 63);
                    result += chars.charAt((bitmap >> 12) & 63);
                    result += i - 2 < str.length ? chars.charAt((bitmap >> 6) & 63) : '=';
                    result += i - 1 < str.length ? chars.charAt(bitmap & 63) : '=';
                }
                
                return result;
            }
        } catch (error) {
            return str; // Fallback to original string
        }
    }

    /**
     * Create a secure fetch wrapper
     */
    async secureFetch(url, options = {}) {
        const method = options.method || 'GET';
        const path = new URL(url, this.config.baseURL).pathname;
        
        // Generate security headers
        const securityHeaders = await this.generateSecurityHeaders(method, path, {
            sensitive: options.sensitive || false
        });

        // Merge with existing headers
        const headers = {
            ...options.headers,
            ...securityHeaders
        };

        // Add Content-Type if not present and we have a body
        if (options.body && !headers['Content-Type']) {
            headers['Content-Type'] = 'application/json';
        }

        const enhancedOptions = {
            ...options,
            headers
        };

        if (this.config.debug) {
            console.log('[AdvancedSecurity] Making secure request to:', url);
        }

        return fetch(url, enhancedOptions);
    }

    /**
     * Update configuration
     */
    updateConfig(newConfig) {
        this.config = { ...this.config, ...newConfig };
        if (this.config.debug) {
            console.log('[AdvancedSecurity] Configuration updated');
        }
    }

    /**
     * Get environment information
     */
    getEnvironmentInfo() {
        return {
            isWasm: this.isWasmEnvironment,
            isWebWorker: this.isWebWorkerEnvironment,
            hasWebCrypto: typeof crypto !== 'undefined' && !!crypto.subtle,
            userAgent: this.getUserAgent()
        };
    }
}

// Export for different module systems
if (typeof module !== 'undefined' && module.exports) {
    // Node.js/CommonJS
    module.exports = AdvancedSecurityClient;
} else if (typeof define === 'function' && define.amd) {
    // AMD
    define([], function() {
        return AdvancedSecurityClient;
    });
} else if (typeof self !== 'undefined') {
    // Web Worker
    self.AdvancedSecurityClient = AdvancedSecurityClient;
} else if (typeof window !== 'undefined') {
    // Browser global
    window.AdvancedSecurityClient = AdvancedSecurityClient;
}

// WebAssembly specific initialization
if (typeof WebAssembly !== 'undefined') {
    // Auto-initialize for WASM environments
    if (typeof globalThis !== 'undefined') {
        globalThis.AdvancedSecurityClient = AdvancedSecurityClient;
    }
}
