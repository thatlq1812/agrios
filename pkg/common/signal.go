package common

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"
)

// WaitForShutdown blocks until an interrupt or termination signal is received
// Returns a context with timeout for graceful shutdown
func WaitForShutdown(timeout time.Duration) context.Context {
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	sig := <-quit
	log.Printf("Received shutdown signal: %v. Initiating graceful shutdown...", sig)

	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	go func() {
		<-ctx.Done()
		cancel()
	}()

	return ctx
}
